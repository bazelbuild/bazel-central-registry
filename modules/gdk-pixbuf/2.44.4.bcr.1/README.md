# Optional built-in SVG loading

The default library retains the existing raster loaders. To add static SVG
loading, build with `--@gdk-pixbuf//:builtin_svg` and link both the renderer and
`@librsvg//:pixbuf_loader` into the final binary. This flag enables the static
registration calls; without those linked implementations the link fails.
`@gdk-pixbuf//gdk-pixbuf:headers` allows adapters to consume the public API
without depending on the implementation, avoiding a dependency cycle.
The librsvg module contains a complete decode test of this integration.
