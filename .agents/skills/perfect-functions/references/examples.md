# Worked examples

These examples are adapted from Logan Smith's
[How to write the perfect function](https://www.youtube.com/watch?v=2OMRWPOSw9s). Use the ideas across languages.
The syntax is intentionally C++-like.

## Honest is broader than pure

A pure function is honest:

```cpp
int square(int value) {
    return value * value;
}
```

Explicit mutation can also be honest:

```cpp
values.clear();
```

An in-place sort is honest for the same reason:

```cpp
sort(values.begin(), values.end());
```

The caller supplied the only state that changes. Both signatures tell the truth.

`remove_if` has two explicit output channels. It mutates the supplied range and returns its new logical end:

```cpp
auto new_end = remove_if(values.begin(), values.end(), should_remove);
values.erase(new_end, values.end());
```

Mutation is not what makes a function dishonest. Hidden state is.

By contrast, a clock read has a hidden input:

```cpp
Time get_time();
```

The function has no parameter representing the changing system clock. Treat it as dishonest and call it near a
boundary.

## Do not wait for repetition

The video argues that the duplication threshold for considering a function is one. A function can improve local
reasoning, abstraction, and testability before any code is reused:

```cpp
auto path = config_file_path();
auto config = read_config(path);
```

This is a prompt to notice a useful concept, not an order to extract every expression. A function should still earn a
name and boundary.

## A dishonest accessor

This name suggests a stable query, but the result depends on hidden asset-manager state:

```cpp
vector<Asset> required_assets() {
    return all_assets() | filter([](const Asset& asset) {
        return !global_asset_manager().already_loaded(asset);
    });
}
```

Either rename it to reveal the stateful behavior or make the state explicit:

```cpp
vector<Asset> unloaded_required_assets(
    span<const Asset> assets,
    const LoadedAssets& loaded
);
```

## Separate core logic from I/O

Interleaving permutation logic with console output makes the algorithm hard to test. One option returns the full
result:

```cpp
vector<string> all_permutations(string input);

int main() {
    for (const auto& value : all_permutations(read_line()))
        println("{}", value);
}
```

That eager result can require factorial memory. A callback keeps the dependency explicit without collecting every
value:

```cpp
void for_each_permutation(string input, auto visit) {
    sort(input.begin(), input.end());
    do {
        visit(input);
    } while (next_permutation(input.begin(), input.end()));
}
```

An iterator, generator, or stream may express the same boundary more naturally in another language.

## Inject randomness

Hidden randomness makes particle creation hard to reproduce:

```cpp
void ParticleWorld::populate(size_t count) {
    particles.push_back(Particle{
        .position = global_random().vec3(),
        .velocity = global_random().vec3(),
    });
}
```

Pass the generator through the signature:

```cpp
void ParticleWorld::populate(size_t count, Random& random) {
    particles.push_back(Particle{
        .position = random.vec3(),
        .velocity = random.vec3(),
    });
}

int main() {
    Random random{system_entropy()};
    world.populate(42, random);
}
```

Tests can pass a known seed. Production can seed from the clock or operating system at the boundary.

## Make wide calls readable

This call hides the meaning of its booleans and invites argument-order mistakes:

```cpp
set_timer(nullptr, "refresh", 5, true, false, true);
```

A purpose-built parameter object exposes the meaning:

```cpp
set_timer(SetTimerParams{
    .id = "refresh",
    .interval = 5s,
    .delay = true,
    .loop = false,
    .retriggerable = true,
});
```

Strong types can also help when the domain reuses the same primitive type for different meanings. Use either approach
when it prevents real confusion. Six wrappers around obvious values can be worse than the original call.

## Ask for the card, not the wallet

If a function needs an account ID and locale, do not require an entire mutable session object:

```cpp
Receipt purchase(AccountId account, Locale locale, Cart cart);
```

This admits more callers, narrows coupling, and makes the true dependencies visible.

Likewise, accept the weakest collection contract the body needs:

```cpp
int sum(span<const int> values);
```

If contiguity is irrelevant, accept an iterable or range instead. If the implementation uses `memcpy`, then requiring
contiguous storage is honest rather than restrictive.

## Turn sequencing into data

A comment cannot enforce this precondition:

```cpp
// mutex must be locked
Result update_shared_state();
```

The video passes a scoped lock as a handstamp:

```cpp
Result update_shared_state(const scoped_lock<TheMutex>& lock);
```

This also catches an unnamed temporary that unlocks immediately:

```cpp
scoped_lock{mutex}; // destroyed at the semicolon
update_shared_state();
```

A generic `scoped_lock<Mutex>` only proves that some mutex of that type is locked. A hardened design ties the guard to
the exact protected state:

```cpp
auto guard = state.lock();
state.update(guard);
```

Only `state.lock()` should be able to create the guard accepted by `state.update`. Use this pattern when the language
can express the ownership relationship safely.

## Put invariants in types, carefully

The bounce calculation requires a unit-length normal. A plain `Vec3` signature hides that precondition:

```cpp
Vec3 bounce(Vec3 velocity, Vec3 normal);
```

A dedicated type can expose it:

```cpp
Vec3 bounce(Vec3 velocity, UnitVec3 normal);
```

Construct `UnitVec3` through checked normalization and expose operations that preserve unit length. Publicly inheriting
all mutable `Vec3` operations is unsafe because callers may break the invariant after construction. Prefer composition
or a restricted interface.

The video suggests implicit conversion to `Vec3` and considers public inheritance. The invariant and caller-focused
contract are faithful to the video. This skill deliberately hardens the representation because a mutable base class
can invalidate the promise.

Do not encode every mathematical fact in the type system. Add a type when it prevents a likely or costly error and
remains pleasant at call sites.

## Write the function you need before knowing its internals

Keep the current train of thought by sketching the desired call:

```cpp
particle.velocity = bounce_velocity(particle.velocity, surface.normal());
```

Implement the reflection math afterward. The call first establishes the right abstraction and contract before
lower-level details take over.

## Keep one level of abstraction

This function mixes a business question with ASCII conversion and a handwritten binary search:

```cpp
bool AssetManager::is_asset_of_type(string name, AssetType type) const {
    lowercase_ascii_in_place(name);
    // handwritten binary search over assets
    // compare the found asset's type
}
```

Move lookup policy into the data structure that owns it:

```cpp
bool AssetManager::is_asset_of_type(string_view name, AssetType type) const {
    const Asset* asset = assets_by_name.find(name);
    return asset && asset->type == type;
}
```

The top-level body now answers the business question. The case-insensitive map owns normalization and lookup. A
standard search algorithm is usually better than wrapping a handwritten one in a helper.

## Keep framework hooks thin

The video treats framework hooks as a third kind of function. Ordinary functions hide their implementation from a
visible call site. Hooks hide the call site from the implementation. Limit them to adaptation:

```cpp
void FrameworkApp::update(Frame frame) {
    simulation.step(frame.delta());
    renderer.draw(simulation.snapshot());
}

int main() {
    return run_application();
}
```

Do not bury domain rules in a callback whose lifecycle and invocation are controlled elsewhere.

## Spot abstraction jumps

Phase comments often reveal several lower-level operations living inside one function:

```cpp
// normalize name
// binary search
// validate type
```

Ask whether each phase is a reusable conceptual operation or belongs to a better owning type. Do not blindly extract
every section. A helper should improve reasoning, testing, side-effect isolation, or change boundaries.
