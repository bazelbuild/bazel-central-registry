#include <chrono>
#include <memory>
#include <string>

#include "gtest/gtest.h"
#include "rules_cc/cc/runfiles/runfiles.h"

#include "aos/configuration.h"
#include "aos/events/simulated_event_loop.h"
#include "example/counter_static.h"

namespace {

using rules_cc::cc::runfiles::Runfiles;

aos::FlatbufferDetachedBuffer<aos::Configuration> ReadTestConfig() {
  std::string error;
  std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
  EXPECT_NE(runfiles, nullptr) << error;
  return aos::configuration::ReadConfig(
      runfiles->Rlocation("_main/example/counter_config.json"));
}

// A timer sends a counter every 10ms and a second event loop watches for it.
TEST(EventLoopTest, WatcherSeesEverySend) {
  aos::FlatbufferDetachedBuffer<aos::Configuration> config = ReadTestConfig();
  aos::SimulatedEventLoopFactory factory(&config.message());

  std::unique_ptr<aos::EventLoop> sender_loop = factory.MakeEventLoop("sender");
  aos::Sender<aos::bcr_test::CounterStatic> sender =
      sender_loop->MakeSender<aos::bcr_test::CounterStatic>("/test");
  int sent = 0;
  aos::TimerHandler *timer = sender_loop->AddTimer([&]() {
    aos::Sender<aos::bcr_test::CounterStatic>::StaticBuilder builder =
        sender.MakeStaticBuilder();
    builder->set_value(++sent);
    builder.CheckOk(builder.Send());
  });
  sender_loop->OnRun([&]() {
    timer->Schedule(sender_loop->monotonic_now(),
                    std::chrono::milliseconds(10));
  });

  std::unique_ptr<aos::EventLoop> watcher_loop =
      factory.MakeEventLoop("watcher");
  int received = 0;
  watcher_loop->MakeWatcher("/test", [&](const aos::bcr_test::Counter &c) {
    EXPECT_EQ(c.value(), ++received);
  });

  factory.RunFor(std::chrono::seconds(1));

  EXPECT_GT(sent, 90);
  EXPECT_EQ(received, sent);
}

// A fetcher sees the most recent message.
TEST(EventLoopTest, FetcherSeesLatest) {
  aos::FlatbufferDetachedBuffer<aos::Configuration> config = ReadTestConfig();
  aos::SimulatedEventLoopFactory factory(&config.message());

  std::unique_ptr<aos::EventLoop> loop = factory.MakeEventLoop("test");
  aos::Sender<aos::bcr_test::CounterStatic> sender =
      loop->MakeSender<aos::bcr_test::CounterStatic>("/test");
  aos::Fetcher<aos::bcr_test::Counter> fetcher =
      loop->MakeFetcher<aos::bcr_test::Counter>("/test");
  EXPECT_FALSE(fetcher.Fetch());

  for (int i = 1; i <= 3; ++i) {
    aos::Sender<aos::bcr_test::CounterStatic>::StaticBuilder builder =
        sender.MakeStaticBuilder();
    builder->set_value(i);
    builder.CheckOk(builder.Send());
  }

  ASSERT_TRUE(fetcher.Fetch());
  EXPECT_EQ(fetcher->value(), 3);
}

}  // namespace
