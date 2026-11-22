#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libavutil/channel_layout.h>
#include <libavutil/error.h>
#include <libavutil/frame.h>
#include <libavutil/log.h>
#include <libavutil/opt.h>
#include <libavutil/samplefmt.h>

typedef struct CodecCase {
    const char *name;
    enum AVCodecID id;
    int encoder;
    int enabled;
    const char *decoder_name;
} CodecCase;

#define DECODER(name, id, flag) \
    { name, id, 0, FFMPEG_BAZEL_COMPONENT_ ## flag, NULL }
#define ENCODER(name, id, flag, decoder) \
    { name, id, 1, FFMPEG_BAZEL_COMPONENT_ ## flag, decoder }

static const CodecCase codec_cases[] = {
    DECODER("libcodec2", AV_CODEC_ID_CODEC2, LIBCODEC2_DECODER),
    ENCODER("libcodec2", AV_CODEC_ID_CODEC2, LIBCODEC2_ENCODER, "libcodec2"),
    DECODER("libdav1d", AV_CODEC_ID_AV1, LIBDAV1D_DECODER),
    DECODER("libgsm", AV_CODEC_ID_GSM, LIBGSM_DECODER),
    ENCODER("libgsm", AV_CODEC_ID_GSM, LIBGSM_ENCODER, "libgsm"),
    DECODER("libgsm_ms", AV_CODEC_ID_GSM_MS, LIBGSM_MS_DECODER),
    ENCODER("libgsm_ms", AV_CODEC_ID_GSM_MS, LIBGSM_MS_ENCODER, "libgsm_ms"),
    DECODER("libjxl_anim", AV_CODEC_ID_JPEGXL_ANIM, LIBJXL_ANIM_DECODER),
    ENCODER("libjxl_anim", AV_CODEC_ID_JPEGXL_ANIM, LIBJXL_ANIM_ENCODER, "libjxl_anim"),
    DECODER("libjxl", AV_CODEC_ID_JPEGXL, LIBJXL_DECODER),
    ENCODER("libjxl", AV_CODEC_ID_JPEGXL, LIBJXL_ENCODER, "libjxl"),
    ENCODER("libmp3lame", AV_CODEC_ID_MP3, LIBMP3LAME_ENCODER, "mp3"),
    ENCODER("libopenjpeg", AV_CODEC_ID_JPEG2000, LIBOPENJPEG_ENCODER, "jpeg2000"),
    ENCODER("librav1e", AV_CODEC_ID_AV1, LIBRAV1E_ENCODER, "libdav1d"),
    ENCODER("libshine", AV_CODEC_ID_MP3, LIBSHINE_ENCODER, "mp3"),
    DECODER("libspeex", AV_CODEC_ID_SPEEX, LIBSPEEX_DECODER),
    ENCODER("libspeex", AV_CODEC_ID_SPEEX, LIBSPEEX_ENCODER, "libspeex"),
    ENCODER("libtwolame", AV_CODEC_ID_MP2, LIBTWOLAME_ENCODER, "mp2"),
    DECODER("libvorbis", AV_CODEC_ID_VORBIS, LIBVORBIS_DECODER),
    ENCODER("libvorbis", AV_CODEC_ID_VORBIS, LIBVORBIS_ENCODER, "libvorbis"),
    ENCODER("libxvid", AV_CODEC_ID_MPEG4, LIBXVID_ENCODER, "mpeg4"),
};

typedef struct CodecRun {
    const char *name;
    AVCodecContext *encoder;
    AVCodecContext *decoder;
    AVFrame *decoded_frame;
    int packets;
    int decoded_frames;
} CodecRun;

static void require(int condition, const char *name, const char *message)
{
    if (!condition) {
        fprintf(stderr, "%s: %s\n", name, message);
        exit(EXIT_FAILURE);
    }
}

static void check(int result, const char *name, const char *operation)
{
    if (result < 0) {
        fprintf(stderr, "%s: %s: %s\n", name, operation, av_err2str(result));
        exit(EXIT_FAILURE);
    }
}

static void check_registration(const CodecCase *test)
{
    const AVCodec *codec = test->encoder ? avcodec_find_encoder_by_name(test->name) :
                                          avcodec_find_decoder_by_name(test->name);
    require(!!codec == test->enabled, test->name,
            test->encoder ? "encoder registration disagrees with its flag" :
                            "decoder registration disagrees with its flag");
    if (codec)
        require(codec->id == test->id, test->name, "unexpected codec ID");
}

static AVCodecContext *open_encoder(const CodecCase *test)
{
    const AVCodec *codec = avcodec_find_encoder_by_name(test->name);
    AVCodecContext *ctx = avcodec_alloc_context3(codec);
    require(ctx != NULL, test->name, "allocating encoder context");
    ctx->thread_count = 1;
    ctx->thread_type = 0;

    if (codec->type == AVMEDIA_TYPE_AUDIO) {
        ctx->ch_layout = (AVChannelLayout)AV_CHANNEL_LAYOUT_MONO;
        ctx->sample_rate = 44100;
        ctx->bit_rate = 64000;
        ctx->sample_fmt = AV_SAMPLE_FMT_S16;
        if (test->id == AV_CODEC_ID_CODEC2 || test->id == AV_CODEC_ID_GSM ||
            test->id == AV_CODEC_ID_GSM_MS || test->id == AV_CODEC_ID_SPEEX) {
            ctx->sample_rate = 8000;
            ctx->bit_rate = 0;
        } else if (test->id == AV_CODEC_ID_MP3) {
            ctx->sample_fmt = AV_SAMPLE_FMT_S16P;
        } else if (test->id == AV_CODEC_ID_VORBIS) {
            ctx->sample_fmt = AV_SAMPLE_FMT_FLTP;
        }
        ctx->time_base = (AVRational){ 1, ctx->sample_rate };
    } else {
        ctx->width = ctx->height = 64;
        ctx->time_base = (AVRational){ 1, 25 };
        ctx->framerate = (AVRational){ 25, 1 };
        ctx->gop_size = 1;
        ctx->keyint_min = 1;
        ctx->max_b_frames = 0;
        ctx->pix_fmt = AV_PIX_FMT_RGB24;
        ctx->color_range = AVCOL_RANGE_JPEG;
        ctx->color_primaries = AVCOL_PRI_BT709;
        ctx->color_trc = AVCOL_TRC_IEC61966_2_1;
        ctx->colorspace = AVCOL_SPC_RGB;
        if (test->id == AV_CODEC_ID_AV1 || test->id == AV_CODEC_ID_MPEG4) {
            ctx->pix_fmt = AV_PIX_FMT_YUV420P;
            ctx->color_range = AVCOL_RANGE_MPEG;
            ctx->color_trc = AVCOL_TRC_BT709;
            ctx->colorspace = AVCOL_SPC_BT709;
        }
        if (test->id == AV_CODEC_ID_AV1) {
            check(av_opt_set_int(ctx->priv_data, "speed", 10, 0), test->name, "setting rav1e speed");
            check(av_opt_set_int(ctx->priv_data, "qp", 100, 0), test->name, "setting rav1e quantizer");
            check(av_opt_set(ctx->priv_data, "rav1e-params",
                             "low_latency=true:rdo_lookahead_frames=1", 0),
                  test->name, "setting rav1e lookahead");
        } else if (test->id == AV_CODEC_ID_JPEGXL || test->id == AV_CODEC_ID_JPEGXL_ANIM) {
            check(av_opt_set_int(ctx->priv_data, "effort", 1, 0), test->name, "setting JPEG XL effort");
        } else if (test->id == AV_CODEC_ID_MPEG4) {
            ctx->bit_rate = 200000;
        }
    }
    check(avcodec_open2(ctx, codec, NULL), test->name, "opening encoder");
    return ctx;
}

static AVCodecContext *open_decoder(const CodecCase *test, const AVCodecContext *encoder)
{
    const AVCodec *codec = avcodec_find_decoder_by_name(test->decoder_name);
    AVCodecParameters *parameters;
    AVCodecContext *ctx;
    if (!codec && test->id == AV_CODEC_ID_MP3)
        codec = avcodec_find_decoder_by_name("mp3float");
    if (!codec && test->id == AV_CODEC_ID_MP2)
        codec = avcodec_find_decoder_by_name("mp2float");
    if (!codec)
        return NULL;
    parameters = avcodec_parameters_alloc();
    ctx = avcodec_alloc_context3(codec);
    require(parameters && ctx, test->name, "allocating decoder context");
    check(avcodec_parameters_from_context(parameters, encoder), test->name, "copying encoder parameters");
    check(avcodec_parameters_to_context(ctx, parameters), test->name, "setting decoder parameters");
    avcodec_parameters_free(&parameters);
    ctx->thread_count = 1;
    ctx->thread_type = 0;
    ctx->pkt_timebase = encoder->time_base;
    check(avcodec_open2(ctx, codec, NULL), test->name, "opening decoder");
    return ctx;
}

static AVFrame *allocate_frame(const AVCodecContext *encoder, const char *name)
{
    AVFrame *frame = av_frame_alloc();
    require(frame != NULL, name, "allocating input frame");
    if (encoder->codec_type == AVMEDIA_TYPE_AUDIO) {
        require(encoder->frame_size > 0 && encoder->frame_size <= 8192,
                name, "unexpected audio frame size");
        frame->format = encoder->sample_fmt;
        frame->nb_samples = encoder->frame_size;
        frame->sample_rate = encoder->sample_rate;
        check(av_channel_layout_copy(&frame->ch_layout, &encoder->ch_layout), name, "copying channel layout");
    } else {
        frame->format = encoder->pix_fmt;
        frame->width = encoder->width;
        frame->height = encoder->height;
        frame->color_range = encoder->color_range;
        frame->color_primaries = encoder->color_primaries;
        frame->color_trc = encoder->color_trc;
        frame->colorspace = encoder->colorspace;
        frame->duration = 1;
    }
    check(av_frame_get_buffer(frame, 0), name, "allocating input samples");
    return frame;
}

static void fill_frame(AVFrame *frame, int sequence, const char *name)
{
    check(av_frame_make_writable(frame), name, "making input frame writable");
    if (frame->nb_samples) {
        frame->pts = (int64_t)sequence * frame->nb_samples;
        for (int i = 0; i < frame->nb_samples; ++i) {
            int sample = ((frame->pts + i) % 64 - 32) * 256;
            if (frame->format == AV_SAMPLE_FMT_FLTP)
                ((float *)frame->data[0])[i] = sample / 32768.0f;
            else
                ((int16_t *)frame->data[0])[i] = sample;
        }
    } else {
        frame->pts = sequence;
        if (frame->format == AV_PIX_FMT_RGB24) {
            for (int y = 0; y < frame->height; ++y)
                for (int x = 0; x < frame->width * 3; ++x)
                    frame->data[0][y * frame->linesize[0] + x] = (x + 5 * y + 7 * sequence) & 255;
        } else {
            for (int y = 0; y < frame->height; ++y)
                for (int x = 0; x < frame->width; ++x)
                    frame->data[0][y * frame->linesize[0] + x] = 16 + (x + y + 9 * sequence) % 220;
            for (int y = 0; y < frame->height / 2; ++y) {
                memset(frame->data[1] + y * frame->linesize[1], 96 + sequence, frame->width / 2);
                memset(frame->data[2] + y * frame->linesize[2], 160 - sequence, frame->width / 2);
            }
        }
    }
}

static int receive_frames(CodecRun *run)
{
    AVFrame *frame = run->decoded_frame;
    int result;
    while ((result = avcodec_receive_frame(run->decoder, frame)) >= 0) {
        require(frame->data[0] && frame->format >= 0, run->name, "decoder returned no samples");
        if (run->encoder->codec_type == AVMEDIA_TYPE_AUDIO) {
            require(frame->nb_samples > 0, run->name, "decoder returned empty audio");
            require(frame->sample_rate == run->encoder->sample_rate, run->name, "sample rate changed");
            require(frame->ch_layout.nb_channels == 1, run->name, "channel count changed");
        } else {
            require(frame->width == run->encoder->width && frame->height == run->encoder->height,
                    run->name, "video dimensions changed");
        }
        ++run->decoded_frames;
        av_frame_unref(frame);
    }
    if (result != AVERROR(EAGAIN) && result != AVERROR_EOF)
        check(result, run->name, "receiving decoded frame");
    return result;
}

static int receive_packets(CodecRun *run, AVPacket *packet)
{
    int result;
    while ((result = avcodec_receive_packet(run->encoder, packet)) >= 0) {
        if (packet->size > 0) {
            ++run->packets;
            if (run->decoder) {
                check(avcodec_send_packet(run->decoder, packet), run->name, "sending encoded packet to decoder");
                receive_frames(run);
            }
        }
        av_packet_unref(packet);
    }
    if (result != AVERROR(EAGAIN) && result != AVERROR_EOF)
        check(result, run->name, "receiving encoded packet");
    return result;
}

static void exercise_encoder(const CodecCase *test)
{
    CodecRun run = { .name = test->name };
    AVFrame *frame;
    AVPacket *packet = av_packet_alloc();
    int frame_count, result;
    require(packet != NULL, test->name, "allocating packet");
    run.encoder = open_encoder(test);
    run.decoder = open_decoder(test, run.encoder);
    run.decoded_frame = av_frame_alloc();
    require(run.decoded_frame != NULL, test->name, "allocating decoded frame");
    frame = allocate_frame(run.encoder, test->name);
    frame_count = frame->nb_samples ? (2048 + frame->nb_samples - 1) / frame->nb_samples : 3;
    for (int i = 0; i < frame_count; ++i) {
        fill_frame(frame, i, test->name);
        check(avcodec_send_frame(run.encoder, frame), test->name, "sending input frame");
        receive_packets(&run, packet);
    }
    check(avcodec_send_frame(run.encoder, NULL), test->name, "flushing encoder");
    require(receive_packets(&run, packet) == AVERROR_EOF, test->name, "encoder did not finish draining");
    require(run.packets > 0, test->name, "encoder produced no packets");
    if (run.decoder) {
        result = avcodec_send_packet(run.decoder, NULL);
        if (result != AVERROR_EOF)
            check(result, test->name, "flushing decoder");
        require(receive_frames(&run) == AVERROR_EOF, test->name, "decoder did not finish draining");
        require(run.decoded_frames > 0, test->name, "decoder produced no frames");
        if (run.encoder->codec_type == AVMEDIA_TYPE_VIDEO)
            require(run.decoded_frames == frame_count, test->name, "decoded video frame count changed");
    }
    printf("%s: %d packets, %d decoded frames%s\n", test->name,
           run.packets, run.decoded_frames, run.decoder ? "" : " (decoder disabled)");
    av_frame_free(&frame);
    av_frame_free(&run.decoded_frame);
    av_packet_free(&packet);
    avcodec_free_context(&run.decoder);
    avcodec_free_context(&run.encoder);
}

static void check_muxer(const char *name, enum AVCodecID expected)
{
    const AVOutputFormat *format = av_guess_format(name, NULL, NULL);
    if (format)
        require(format->audio_codec == expected, name, "default audio codec disagrees with component flags");
}

int main(void)
{
    const int lame = FFMPEG_BAZEL_COMPONENT_LIBMP3LAME_ENCODER;
    const int vorbis_encoder = FFMPEG_BAZEL_COMPONENT_LIBVORBIS_ENCODER;
    const int vorbis = vorbis_encoder || FFMPEG_BAZEL_COMPONENT_LIBVORBIS_DECODER;
    const int gplv3 = FFMPEG_BAZEL_COMPONENT_LIBX264_ENCODER ||
                      FFMPEG_BAZEL_COMPONENT_LIBX264RGB_ENCODER ||
                      FFMPEG_BAZEL_COMPONENT_LIBX265_ENCODER ||
                      FFMPEG_BAZEL_COMPONENT_LIBXVID_ENCODER ||
                      FFMPEG_BAZEL_COMPONENT_GPLV3;
    const char *license = gplv3 ? "GPL version 3 or later" :
                          FFMPEG_BAZEL_COMPONENT_LGPLV3 ? "LGPL version 3 or later" :
                                                         "LGPL version 2.1 or later";
    av_log_set_level(AV_LOG_ERROR);
    require(strcmp(av_version_info(), "9.0.1") == 0, "ffmpeg", "unexpected upstream version");
    require(strcmp(avutil_license(), license) == 0, "avutil", "license disagrees with component flags");
    require(strcmp(avcodec_license(), license) == 0, "avcodec", "license disagrees with component flags");
    require(strcmp(avformat_license(), license) == 0, "avformat", "license disagrees with component flags");
    for (size_t i = 0; i < sizeof(codec_cases) / sizeof(codec_cases[0]); ++i)
        check_registration(&codec_cases[i]);
    for (size_t i = 0; i < sizeof(codec_cases) / sizeof(codec_cases[0]); ++i)
        if (codec_cases[i].enabled && codec_cases[i].encoder)
            exercise_encoder(&codec_cases[i]);
    check_muxer("avi", lame ? AV_CODEC_ID_MP3 : AV_CODEC_ID_AC3);
    check_muxer("flv", lame ? AV_CODEC_ID_MP3 : AV_CODEC_ID_ADPCM_SWF);
    check_muxer("nut", vorbis ? AV_CODEC_ID_VORBIS : lame ? AV_CODEC_ID_MP3 : AV_CODEC_ID_MP2);
    check_muxer("ogg", vorbis_encoder ? AV_CODEC_ID_VORBIS : AV_CODEC_ID_FLAC);
    return 0;
}
