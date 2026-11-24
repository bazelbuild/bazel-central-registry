// Constructs a client from each hand-written library and from services that
// need more than core, so the test fails to link if a dependency is missing.
#include <aws/access-management/AccessManagementClient.h>
#include <aws/cognito-identity/CognitoIdentityClient.h>
#include <aws/core/Aws.h>
#include <aws/core/SDKConfig.h>
#include <aws/core/client/ClientConfiguration.h>
#include <aws/core/utils/crypto/Cipher.h>
#include <aws/core/utils/threading/Executor.h>
#include <aws/iam/IAMClient.h>
#include <aws/monitoring/CloudWatchClient.h>
#include <aws/polly/PollyClient.h>
#include <aws/queues/sqs/SQSQueue.h>
#include <aws/s3-crt/S3CrtClient.h>
#include <aws/s3-encryption/S3EncryptionClient.h>
#include <aws/s3-encryption/materials/SimpleEncryptionMaterials.h>
#include <aws/s3-transfer/S3TransferManager.h>
#include <aws/s3/S3Client.h>
#include <aws/sqs/SQSClient.h>
#include <aws/text-to-speech/TextToSpeechManager.h>
#include <aws/transfer/TransferManager.h>

#include <cstdio>
#include <memory>

// Set by BUILD.bazel to the values of @aws_sdk//:memory_management and
// @aws_sdk//:user_agent_customization, so the test checks that core was built
// with them.
#if defined(EXPECT_MEMORY_MANAGEMENT) != defined(USE_AWS_MEMORY_MANAGEMENT)
#error "SDKConfig.h does not match @aws_sdk//:memory_management"
#endif

int main() {
  Aws::SDKOptions options;
  Aws::InitAPI(options);
  int failures = 0;
  {
    Aws::Client::ClientConfiguration config;
    config.region = "us-east-1";

#ifdef EXPECT_USER_AGENT_TOKEN
    const Aws::String user_agent = Aws::Client::ComputeUserAgentString(&config);
    if (user_agent.find(EXPECT_USER_AGENT_TOKEN) == Aws::String::npos) {
      std::fprintf(stderr, "User-Agent lacks %s: %s\n", EXPECT_USER_AGENT_TOKEN, user_agent.c_str());
      ++failures;
    }
#endif

    auto iam = std::make_shared<Aws::IAM::IAMClient>(config);
    auto cognito = std::make_shared<Aws::CognitoIdentity::CognitoIdentityClient>(config);
    Aws::AccessManagement::AccessManagementClient access_management(iam, cognito);

    auto sqs = std::make_shared<Aws::SQS::SQSClient>(config);
    Aws::Queues::Sqs::SQSQueue queue(sqs, "components-test", 30);

    Aws::CloudWatch::CloudWatchClient monitoring(config);

    auto polly = std::make_shared<Aws::Polly::PollyClient>(config);
    auto text_to_speech = Aws::TextToSpeech::TextToSpeechManager::Create(polly);
    if (text_to_speech == nullptr) {
      std::fprintf(stderr, "TextToSpeechManager::Create returned null\n");
      ++failures;
    }

    Aws::S3Crt::ClientConfiguration crt_config;
    crt_config.region = "us-east-1";
    Aws::S3Crt::S3CrtClient s3_crt(crt_config);

    auto materials = Aws::MakeShared<Aws::S3Encryption::Materials::SimpleEncryptionMaterialsWithGCMAAD>(
        "components_test", Aws::Utils::Crypto::SymmetricCipher::GenerateKey());
    Aws::S3Encryption::CryptoConfigurationV3 crypto_config(materials);
    Aws::S3Encryption::S3EncryptionClientV3 s3_encryption(crypto_config);

    auto s3 = std::make_shared<Aws::S3::S3Client>(config);
    auto executor = Aws::MakeShared<Aws::Utils::Threading::PooledThreadExecutor>("components_test", 1);
    Aws::Transfer::TransferManagerConfiguration transfer_config(executor.get());
    transfer_config.s3Client = s3;
    auto transfer = Aws::Transfer::TransferManager::Create(transfer_config);
    if (transfer == nullptr) {
      std::fprintf(stderr, "TransferManager::Create returned null\n");
      ++failures;
    }

    Aws::S3::Transfer::S3TransferManagerConfiguration s3_transfer_config(config);
    Aws::S3::Transfer::S3TransferManager s3_transfer(s3_transfer_config);
  }
  Aws::ShutdownAPI(options);
  return failures;
}
