// Trains a small model fully in memory, then checks that encoding and
// decoding roundtrips in both SentencePieceProcessor and
// SentencePieceLiteProcessor. This replaces the upstream //src:spm_test, whose
// test data (data/) is not shipped in the release tarball.

#include <iostream>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "absl/status/status.h"
#include "sentencepiece_lite.h"
#include "sentencepiece_model.pb.h"
#include "sentencepiece_model_converters.h"
#include "sentencepiece_processor.h"
#include "sentencepiece_trainer.h"

#define CHECK_TEST(condition)                                  \
  if (!(condition)) {                                          \
    std::cerr << __FILE__ << ":" << __LINE__                   \
              << " check failed: " << #condition << std::endl; \
    return 1;                                                  \
  }

#define CHECK_OK_TEST(expr)                                    \
  {                                                            \
    const absl::Status _status = (expr);                       \
    if (!_status.ok()) {                                       \
      std::cerr << __FILE__ << ":" << __LINE__                 \
                << " status not ok: " << _status << std::endl; \
      return 1;                                                \
    }                                                          \
  }

int main() {
  const std::vector<std::string> base = {
      "The quick brown fox jumps over the lazy dog.",
      "SentencePiece is an unsupervised text tokenizer and detokenizer.",
      "Hello world. Hello Bazel.",
      "I saw a girl with a telescope.",
  };
  std::vector<std::string> sentences;
  for (int i = 0; i < 200; ++i) {
    sentences.push_back(base[i % base.size()]);
  }

  std::string serialized_model;
  CHECK_OK_TEST(sentencepiece::SentencePieceTrainer::Train(
      "--vocab_size=60 --hard_vocab_limit=false --minloglevel=1", sentences,
      &serialized_model));
  CHECK_TEST(!serialized_model.empty());

  sentencepiece::SentencePieceProcessor sp;
  CHECK_OK_TEST(sp.LoadFromSerializedProto(serialized_model));

  const std::string input = "Hello world.";
  std::vector<std::string> pieces;
  CHECK_OK_TEST(sp.Encode(input, &pieces));
  CHECK_TEST(!pieces.empty());

  std::string detokenized;
  CHECK_OK_TEST(sp.Decode(pieces, &detokenized));
  CHECK_TEST(detokenized == input);

  std::vector<int> ids;
  CHECK_OK_TEST(sp.Encode(input, &ids));
  CHECK_TEST(!ids.empty());

  sentencepiece::ModelProto model_proto;
  CHECK_TEST(model_proto.ParseFromString(serialized_model));
  auto fb_or = sentencepiece::lite::ToFlatbuffer(model_proto);
  CHECK_OK_TEST(fb_or.status());
  auto fb_buf = std::make_shared<std::string>(std::move(*fb_or));
  sentencepiece::lite::SentencePieceLiteProcessor lite_sp(fb_buf);
  CHECK_TEST(lite_sp.status() == sentencepiece::lite::StatusCode::kOk);

  std::vector<int> lite_ids;
  CHECK_TEST(lite_sp.Encode(input, &lite_ids) ==
             sentencepiece::lite::StatusCode::kOk);
  CHECK_TEST(lite_ids == ids);

  std::string lite_detokenized;
  CHECK_TEST(lite_sp.Decode(lite_ids, &lite_detokenized) ==
             sentencepiece::lite::StatusCode::kOk);
  CHECK_TEST(lite_detokenized == input);

  std::cout << "PASS" << std::endl;
  return 0;
}
