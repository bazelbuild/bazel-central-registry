// Trains a small model fully in memory, then checks that encoding and
// decoding roundtrips. This is a self-contained smoke test of the public
// API, kept independent of the upstream //src:spm_test and its data/ files.

#include <iostream>
#include <string>
#include <vector>

#include "absl/status/status.h"
#include "sentencepiece_processor.h"
#include "sentencepiece_trainer.h"

#define CHECK_TEST(condition)                                     \
  if (!(condition)) {                                             \
    std::cerr << __FILE__ << ":" << __LINE__ << " check failed: " \
              << #condition << std::endl;                         \
    return 1;                                                     \
  }

#define CHECK_OK_TEST(expr)                                         \
  {                                                                 \
    const absl::Status _status = (expr);                            \
    if (!_status.ok()) {                                            \
      std::cerr << __FILE__ << ":" << __LINE__                      \
                << " status not ok: " << _status << std::endl;      \
      return 1;                                                     \
    }                                                               \
  }

namespace {

// Feeds SentencePieceTrainer from an in-memory vector of sentences.
class VectorSentenceIterator : public sentencepiece::SentenceIterator {
 public:
  explicit VectorSentenceIterator(const std::vector<std::string>& sentences)
      : sentences_(sentences) {}

  bool done() const override { return index_ >= sentences_.size(); }
  void Next() override { ++index_; }
  const std::string& value() const override { return sentences_[index_]; }
  absl::Status status() const override { return absl::OkStatus(); }

 private:
  const std::vector<std::string>& sentences_;
  size_t index_ = 0;
};

}  // namespace

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

  VectorSentenceIterator it(sentences);
  sentencepiece::TrainerComponents components;
  components.sentence_iterator = &it;

  std::string serialized_model;
  CHECK_OK_TEST(sentencepiece::SentencePieceTrainer::Train(
      "--vocab_size=60 --hard_vocab_limit=false --minloglevel=1", components,
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

  std::cout << "PASS" << std::endl;
  return 0;
}
