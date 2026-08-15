#include "src/devices/IKeyboard.hpp"
#include "src/devices/IPointer.hpp"
#include "src/event/EventBus.hpp"
#include "src/managers/input/InputManager.hpp"
#include "src/plugins/PluginAPI.hpp"

#include <algorithm>
#include <array>
#include <cerrno>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <cstdint>
#include <cstdio>
#include <fcntl.h>
#include <memory>
#include <mutex>
#include <spawn.h>
#include <sys/wait.h>
#include <thread>
#include <unistd.h>

extern char** environ;

namespace {

constexpr double SCROLL_UNITS_PER_STEP = 12.0;
constexpr int MAX_PENDING_STEPS = 12;
constexpr auto MIN_UPDATE_INTERVAL = std::chrono::milliseconds(50);

class CBrightnessWorker {
  public:
    CBrightnessWorker() : m_thread([this] { run(); }) {}

    ~CBrightnessWorker() {
        {
            const std::lock_guard lock(m_mutex);
            m_stopping = true;
        }

        m_wakeup.notify_one();
        m_thread.join();
    }

    void enqueue(const int steps) {
        if (steps == 0)
            return;

        {
            const std::lock_guard lock(m_mutex);

            // A direction reversal should feel immediate, not drain stale work first.
            if ((m_pendingSteps > 0 && steps < 0) || (m_pendingSteps < 0 && steps > 0))
                m_pendingSteps = 0;

            m_pendingSteps = std::clamp(m_pendingSteps + steps, -MAX_PENDING_STEPS, MAX_PENDING_STEPS);
        }

        m_wakeup.notify_one();
    }

  private:
    static void changeBrightness(const int direction) {
        const auto action = direction > 0 ? "brightness-up" : "brightness-down";
        std::array<char*, 6> args = {
            const_cast<char*>("noctalia"),
            const_cast<char*>("msg"),
            const_cast<char*>(action),
            const_cast<char*>("all"),
            const_cast<char*>("1%"),
            nullptr,
        };

        posix_spawn_file_actions_t fileActions;
        if (posix_spawn_file_actions_init(&fileActions) != 0)
            return;
        if (posix_spawn_file_actions_addopen(&fileActions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0) != 0) {
            posix_spawn_file_actions_destroy(&fileActions);
            return;
        }

        pid_t child = 0;
        const int spawnResult = posix_spawnp(&child, args[0], &fileActions, nullptr, args.data(), environ);
        posix_spawn_file_actions_destroy(&fileActions);
        if (spawnResult != 0) {
            std::fprintf(stderr, "[brightness-scroll] failed to start Noctalia: %d\n", spawnResult);
            return;
        }

        int status = 0;
        while (waitpid(child, &status, 0) == -1) {
            if (errno != EINTR)
                return;
        }
    }

    void run() {
        auto nextUpdate = std::chrono::steady_clock::now();

        while (true) {
            int direction = 0;
            {
                std::unique_lock lock(m_mutex);
                m_wakeup.wait(lock, [this] { return m_stopping || m_pendingSteps != 0; });

                if (m_stopping)
                    return;

                direction = m_pendingSteps > 0 ? 1 : -1;
                m_pendingSteps -= direction;
            }

            if (const auto now = std::chrono::steady_clock::now(); now < nextUpdate)
                std::this_thread::sleep_until(nextUpdate);

            nextUpdate = std::chrono::steady_clock::now() + MIN_UPDATE_INTERVAL;
            changeBrightness(direction);
        }
    }

    std::mutex m_mutex;
    std::condition_variable m_wakeup;
    std::thread m_thread;
    int m_pendingSteps = 0;
    bool m_stopping = false;
};

CHyprSignalListener g_axisListener;
std::unique_ptr<CBrightnessWorker> g_brightnessWorker;
double g_accumulatedScroll = 0.0;
uint32_t g_lastEventTime = 0;

void resetScroll() {
    g_accumulatedScroll = 0.0;
    g_lastEventTime = 0;
}

void onAxis(const IPointer::SAxisEvent event, Event::SCallbackInfo& info) {
    const bool isFingerScroll = event.source == WL_POINTER_AXIS_SOURCE_FINGER;
    const bool superHeld = g_pInputManager && (g_pInputManager->getModsFromAllKBs() & HL_MODIFIER_META) != 0;

    if (!isFingerScroll || !superHeld) {
        resetScroll();
        return;
    }

    // Super-modified touchpad scrolling belongs exclusively to brightness.
    info.cancelled = true;

    if (event.axis != WL_POINTER_AXIS_VERTICAL_SCROLL)
        return;

    if (event.delta == 0.0) {
        resetScroll();
        return;
    }

    if (g_lastEventTime != 0 && event.timeMs - g_lastEventTime > 250)
        g_accumulatedScroll = 0.0;
    g_lastEventTime = event.timeMs;

    // Recover physical finger direction even when natural scrolling is enabled.
    const double physicalDelta = event.relativeDirection == WL_POINTER_AXIS_RELATIVE_DIRECTION_INVERTED ? -event.delta : event.delta;
    if ((g_accumulatedScroll > 0.0 && physicalDelta < 0.0) || (g_accumulatedScroll < 0.0 && physicalDelta > 0.0))
        g_accumulatedScroll = 0.0;

    g_accumulatedScroll += physicalDelta;
    const int steps = static_cast<int>(std::abs(g_accumulatedScroll) / SCROLL_UNITS_PER_STEP);
    if (steps == 0)
        return;

    const bool fingersMovedUp = g_accumulatedScroll < 0.0;
    g_accumulatedScroll += std::copysign(SCROLL_UNITS_PER_STEP * steps, -g_accumulatedScroll);
    g_brightnessWorker->enqueue(fingersMovedUp ? steps : -steps);
}

} // namespace

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE) {
    g_brightnessWorker = std::make_unique<CBrightnessWorker>();
    g_axisListener = Event::bus()->m_events.input.mouse.axis.listen(onAxis);

    return {
        "brightness-scroll",
        "Live Super + two-finger brightness control",
        "sthom",
        "1.0.0",
    };
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_axisListener.reset();
    g_brightnessWorker.reset();
    resetScroll();
}
