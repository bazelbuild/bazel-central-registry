"""Which C++ extensions have a Bazel recipe, and what it produces.

`source_exts.bzl` is generated: it says what each extension's *layout* is, for
every extension in the tree, and which ones are pure enough to assemble with no
further work. The native ones need a build recipe as well -- a carbonite plugin,
sometimes a pybind module -- and those are written by hand in //BUILD.bazel,
because premake's project definitions do not translate mechanically.

This is the list of the ones that have been written and verified to load. An
extension named here is built from source and dropped from the download lock;
everything else in `ISAACSIM_NATIVE_EXTS` still comes from its prebuilt.
"""

# extension name -> {built library: where it goes inside the extension}
ISAACSIM_NATIVE_PLUGINS = {
    "isaacsim.core.api": {
        ":libisaacsim.core.api.plugin.so": "bin",
    },
    "isaacsim.core.cloner": {
        ":_isaac_cloner.cpython-312-x86_64-linux-gnu.so": "isaacsim/core/cloner/bindings",
    },
    "isaacsim.core.experimental.prims": {
        ":libisaacsim.core.experimental.prims.plugin.so": "bin",
        ":_prims_reader.cpython-312-x86_64-linux-gnu.so": "isaacsim/core/experimental/prims/bindings",
    },
    "isaacsim.core.experimental.primdata": {
        ":libisaacsim.core.experimental.primdata.plugin.so": "bin",
    },
    "isaacsim.core.nodes": {
        ":libisaacsim.core.nodes.plugin.so": "bin",
        ":_isaacsim_core_nodes.cpython-312-x86_64-linux-gnu.so": "isaacsim/core/nodes/bindings",
    },
    "isaacsim.core.simulation_manager": {
        ":libisaacsim.core.simulation_manager.plugin.so": "bin",
        ":_simulation_manager.cpython-312-x86_64-linux-gnu.so": "isaacsim/core/simulation_manager/bindings",
    },
    "isaacsim.core.utils": {
        ":_isaac_utils.cpython-312-x86_64-linux-gnu.so": "isaacsim/core/utils/bindings",
    },
    "isaacsim.sensors.experimental.physics": {
        ":libisaacsim.sensors.experimental.physics.plugin.so": "bin",
        ":_physics_sensors.cpython-312-x86_64-linux-gnu.so": "isaacsim/sensors/experimental/physics/bindings",
    },
    "isaacsim.sensors.rtx": {
        ":libisaacsim.sensors.rtx.plugin.so": "bin",
        ":_isaacsim_sensors_rtx.cpython-312-x86_64-linux-gnu.so": "isaacsim/sensors/rtx/bindings",
    },
    "isaacsim.sensors.physx": {
        ":libisaacsim.sensors.physx.plugin.so": "bin",
        ":_range_sensor.cpython-312-x86_64-linux-gnu.so": "isaacsim/sensors/physx/bindings",
    },
    "isaacsim.sensors.physics.nodes": {
        ":libisaacsim.sensors.physics.nodes.plugin.so": "bin",
        ":_physics_sensor_nodes.cpython-312-x86_64-linux-gnu.so": "isaacsim/sensors/physics/nodes/bindings",
    },
    "omni.kit.loop-isaac": {
        ":libomni.kit.loop-isaac.plugin.so": "bin",
        ":_loop.cpython-312-x86_64-linux-gnu.so": "omni/kit/loop/bindings",
    },
    "isaacsim.robot.surface_gripper": {
        ":libisaacsim.robot.surface_gripper.plugin.so": "bin",
        ":_surface_gripper.cpython-312-x86_64-linux-gnu.so": "isaacsim/robot/surface_gripper/bindings",
    },
    "isaacsim.robot.wheeled_robots.nodes": {
        ":libisaacsim.robot.wheeled_robots.nodes.plugin.so": "bin",
        ":_wheeled_robots_nodes.cpython-312-x86_64-linux-gnu.so": "isaacsim/robot/wheeled_robots/nodes/bindings",
    },
    "isaacsim.robot.wheeled_robots": {
        ":libisaacsim.robot.wheeled_robots.plugin.so": "bin",
        ":_isaacsim_robot_wheeled_robots.cpython-312-x86_64-linux-gnu.so": "isaacsim/robot/wheeled_robots/bindings",
    },
}
