#include <sqlite3.h>

int main() {
  sqlite3* database = nullptr;
  if (sqlite3_open(":memory:", &database) != SQLITE_OK) {
    return 1;
  }

  const int result = sqlite3_exec(
      database, "CREATE TABLE test (value INTEGER);", nullptr, nullptr, nullptr);
  sqlite3_close(database);
  return result == SQLITE_OK ? 0 : 1;
}
