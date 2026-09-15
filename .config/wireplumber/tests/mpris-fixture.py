"""Controllable fake player for the private D-Bus integration test only."""

import sys

from gi.repository import Gio, GLib

name, status = sys.argv[1:]
path = "/org/mpris/MediaPlayer2"
interface = "org.mpris.MediaPlayer2.Player"
bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
node = Gio.DBusNodeInfo.new_for_xml("""
<node>
  <interface name="org.mpris.MediaPlayer2.Player">
    <property name="PlaybackStatus" type="s" access="read"/>
  </interface>
  <interface name="org.example.TestPlayer">
    <method name="SetStatus"><arg type="s" direction="in"/></method>
  </interface>
</node>
""")


def get_property(*_args):
    return GLib.Variant("s", status)


def method(_bus, _sender, _path, _interface, _method, params, invocation):
    global status
    status = params.unpack()[0]
    bus.emit_signal(
        None,
        path,
        "org.freedesktop.DBus.Properties",
        "PropertiesChanged",
        GLib.Variant("(sa{sv}as)", (interface, {"PlaybackStatus": GLib.Variant("s", status)}, [])),
    )
    invocation.return_value(None)


for info in node.interfaces:
    bus.register_object(path, info, method, get_property, None)
Gio.bus_own_name_on_connection(bus, "org.mpris.MediaPlayer2." + name, Gio.BusNameOwnerFlags.NONE, None, None)
GLib.MainLoop().run()
