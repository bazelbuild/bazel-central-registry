#include <stdio.h>

#include <ass/ass.h>

static const char script[] =
    "[Script Info]\n"
    "ScriptType: v4.00+\n"
    "PlayResX: 640\n"
    "PlayResY: 480\n"
    "\n"
    "[V4+ Styles]\n"
    "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, "
    "OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, "
    "ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, "
    "Alignment, MarginL, MarginR, MarginV, Encoding\n"
    "Style: Default,Arial,20,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,"
    "0,0,0,0,100,100,0,0,1,2,2,2,10,10,10,1\n"
    "\n"
    "[Events]\n"
    "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, "
    "Effect, Text\n"
    "Dialogue: 0,0:00:00.00,0:00:05.00,Default,,0,0,0,,Hello, world!\n";

int main(void)
{
    ASS_Library *library = ass_library_init();
    if (!library) {
        fprintf(stderr, "ass_library_init failed\n");
        return 1;
    }

    ASS_Renderer *renderer = ass_renderer_init(library);
    if (!renderer) {
        fprintf(stderr, "ass_renderer_init failed\n");
        return 1;
    }

    ass_set_frame_size(renderer, 640, 480);
    ass_set_fonts(renderer, NULL, "sans-serif", ASS_FONTPROVIDER_AUTODETECT,
                  NULL, 1);

    ASS_Track *track = ass_read_memory(library, (char *) script,
                                       sizeof(script) - 1, NULL);
    if (!track) {
        fprintf(stderr, "ass_read_memory failed\n");
        return 1;
    }
    if (track->n_events != 1) {
        fprintf(stderr, "expected 1 event, got %d\n", track->n_events);
        return 1;
    }

    /* Hosts without usable fonts may yield a NULL image; only exercise the
     * pipeline (parser, shaper, rasterizer) and require it not to crash. */
    int detect_change = 0;
    ass_render_frame(renderer, track, 1000, &detect_change);

    ass_free_track(track);
    ass_renderer_done(renderer);
    ass_library_done(library);

    printf("libass 0.17.5 smoke test passed\n");
    return 0;
}
