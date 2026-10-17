#include <ares.h>
#include <arpa/inet.h>
#include <errno.h>
#include <poll.h>
#include <signal.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdio.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>

struct query_result {
  atomic_bool done;
  ares_status_t status;
  size_t timeouts;
};

static void deadline_expired(int signal_number) {
  (void)signal_number;
  static const char message[] = "event-thread query test exceeded its 30-second deadline\n";
  (void)write(STDERR_FILENO, message, sizeof(message) - 1);
  _exit(1);
}

static void query_finished(void* arg, ares_status_t status, size_t timeouts,
                           const ares_dns_record_t* record) {
  (void)record;
  struct query_result* result = arg;
  result->status = status;
  result->timeouts = timeouts;
  atomic_store_explicit(&result->done, true, memory_order_release);
}

static int receive_query(int socket_fd, const char* name, unsigned short query_id) {
  struct pollfd descriptor = {.fd = socket_fd, .events = POLLIN};
  int ready = poll(&descriptor, 1, 5000);
  if (ready < 0) {
    perror("poll DNS request");
    return 1;
  }
  if (ready == 0 || !(descriptor.revents & POLLIN)) {
    fprintf(stderr, "%s: no UDP request received (poll events: %d)\n", name, descriptor.revents);
    return 1;
  }

  unsigned char packet[4096];
  ssize_t length = recv(socket_fd, packet, sizeof(packet), MSG_DONTWAIT);
  if (length < 0) {
    perror("receive DNS request");
    return 1;
  }
  if (length < 12 || packet[0] != (query_id >> 8) || packet[1] != (query_id & 0xff) ||
      (packet[2] & 0x80) != 0 || packet[4] != 0 || packet[5] != 1) {
    fprintf(stderr, "%s: received an unexpected DNS request (%zd bytes, expected ID %u)\n", name,
            length, query_id);
    return 1;
  }
  return 0;
}

static int check_queries(int socket_fd, struct sockaddr_in* server) {
  struct ares_options options = {0};
  options.resolvconf_path = "/dev/null";
  options.servers = &server->sin_addr;
  options.nservers = 1;
  options.udp_port = ntohs(server->sin_port);
  options.timeout = 100;
  options.maxtimeout = 100;
  options.tries = 1;
  options.evsys = ARES_EVSYS_EPOLL;

  ares_channel_t* channel = NULL;
  int status = ares_init_options(&channel, &options,
                                 ARES_OPT_EVENT_THREAD | ARES_OPT_RESOLVCONF | ARES_OPT_SERVERS |
                                     ARES_OPT_UDP_PORT | ARES_OPT_TIMEOUTMS |
                                     ARES_OPT_MAXTIMEOUTMS | ARES_OPT_TRIES);
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "event-thread channel initialization: %s\n", ares_strerror(status));
    return 1;
  }

  const char* names[] = {"first.test", "second.test", "third.test", "fourth.test"};
  struct query_result results[sizeof(names) / sizeof(names[0])];
  for (size_t i = 0; i < sizeof(results) / sizeof(results[0]); ++i) {
    atomic_init(&results[i].done, false);
  }

  int result = 1;
  for (size_t i = 0; i < sizeof(names) / sizeof(names[0]); ++i) {
    unsigned short query_id = 0;
    status = ares_query_dnsrec(channel, names[i], ARES_CLASS_IN, ARES_REC_TYPE_A, query_finished,
                               &results[i], &query_id);
    if (status != ARES_SUCCESS) {
      fprintf(stderr, "%s: query submission: %s\n", names[i], ares_strerror(status));
      goto done;
    }
    if (receive_query(socket_fd, names[i], query_id) != 0) {
      goto done;
    }

    status = ares_queue_wait_empty(channel, 5000);
    if (status != ARES_SUCCESS) {
      fprintf(stderr, "%s: query was sent but its queue did not drain within 5 seconds: %s\n",
              names[i], ares_strerror(status));
      goto done;
    }
    if (!atomic_load_explicit(&results[i].done, memory_order_acquire)) {
      fprintf(stderr, "%s: empty queue without a query callback\n", names[i]);
      goto done;
    }
    if (results[i].status != ARES_ETIMEOUT || results[i].timeouts != 1) {
      fprintf(stderr, "%s: expected one DNS timeout, got %s with %zu timeouts\n", names[i],
              ares_strerror(results[i].status), results[i].timeouts);
      goto done;
    }
    printf("%s: UDP request received, timeout callback received, queue drained\n", names[i]);

    if (i + 1 < sizeof(names) / sizeof(names[0])) {
      // An empty queue does not acknowledge that the event thread has started waiting.
      struct timespec idle = {.tv_nsec = 200000000};
      while (nanosleep(&idle, &idle) != 0) {
        if (errno != EINTR) {
          perror("wait for idle event thread");
          goto done;
        }
      }
    }
  }
  result = 0;

done:
  ares_destroy(channel);
  return result;
}

int main(void) {
  struct sigaction action = {.sa_handler = deadline_expired};
  if (sigemptyset(&action.sa_mask) != 0 || sigaction(SIGALRM, &action, NULL) != 0) {
    perror("set test deadline");
    return 1;
  }
  alarm(30);

  int socket_fd = socket(AF_INET, SOCK_DGRAM, 0);
  if (socket_fd < 0) {
    perror("create UDP listener");
    return 1;
  }
  struct sockaddr_in server = {
      .sin_family = AF_INET,
      .sin_addr.s_addr = htonl(INADDR_LOOPBACK),
  };
  if (bind(socket_fd, (struct sockaddr*)&server, sizeof(server)) != 0) {
    perror("bind UDP listener");
    close(socket_fd);
    return 1;
  }
  socklen_t address_length = sizeof(server);
  if (getsockname(socket_fd, (struct sockaddr*)&server, &address_length) != 0) {
    perror("get UDP listener port");
    close(socket_fd);
    return 1;
  }

  int status = ares_library_init(ARES_LIB_INIT_ALL);
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "c-ares initialization: %s\n", ares_strerror(status));
    close(socket_fd);
    return 1;
  }

  int result = check_queries(socket_fd, &server);
  close(socket_fd);
  ares_library_cleanup();
  return result;
}
