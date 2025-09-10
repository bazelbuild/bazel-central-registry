#include "google/cloud/storage/client.h"
#include <iostream>

int main(int argc, char* argv[]) {
  try {
    google::cloud::StatusOr<google::cloud::storage::Client> client =
        google::cloud::storage::Client::CreateDefaultClient();
    if (!client) {
      std::cerr << "Failed to create Storage client: " << client.status() << "\n";
      return 1;
    }
    std::cout << "Successfully created a Google Cloud Storage client.\n";
    return 0;
  } catch (google::cloud::basics::BadStatus& ex) {
    std::cerr << "Failed to create Storage client with status: " << ex.status() << "\n";
    return 1;
  }
}
