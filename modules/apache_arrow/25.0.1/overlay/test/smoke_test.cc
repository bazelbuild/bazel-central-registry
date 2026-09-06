#include <arrow/api.h>
#include <arrow/compute/api.h>
#include <arrow/compute/initialize.h>
#include <arrow/dataset/file_parquet.h>
#include <arrow/io/api.h>
#include <arrow/util/compression.h>
#include <parquet/arrow/reader.h>
#include <parquet/arrow/writer.h>

#include <iostream>
#include <memory>
#include <vector>

int main() {
  arrow::Int64Builder builder;
  auto status = builder.AppendValues({1, 2, 3});
  if (!status.ok()) {
    std::cerr << status << '\n';
    return 1;
  }

  auto array_result = builder.Finish();
  if (!array_result.ok()) {
    std::cerr << array_result.status() << '\n';
    return 1;
  }
  auto values = *array_result;
  status = arrow::compute::Initialize();
  if (!status.ok()) {
    std::cerr << status << '\n';
    return 1;
  }
  auto sum = arrow::compute::CallFunction("add", {values, values});
  if (!sum.ok()) {
    std::cerr << sum.status() << '\n';
    return 1;
  }

  auto table = arrow::Table::Make(
      arrow::schema({arrow::field("value", arrow::int64())}), {values});
  auto sink_result = arrow::io::BufferOutputStream::Create();
  if (!sink_result.ok()) {
    std::cerr << sink_result.status() << '\n';
    return 1;
  }
  auto sink = *sink_result;
  status = parquet::arrow::WriteTable(*table, arrow::default_memory_pool(), sink, 3);
  if (!status.ok()) {
    std::cerr << status << '\n';
    return 1;
  }

  auto buffer_result = sink->Finish();
  if (!buffer_result.ok()) {
    std::cerr << buffer_result.status() << '\n';
    return 1;
  }
  auto source = std::make_shared<arrow::io::BufferReader>(*buffer_result);
  auto reader_result = parquet::arrow::OpenFile(source, arrow::default_memory_pool());
  if (!reader_result.ok()) {
    std::cerr << reader_result.status() << '\n';
    return 1;
  }
  auto reader = std::move(*reader_result);

  auto restored_result = reader->ReadTable();
  if (!restored_result.ok() || !(*restored_result)->Equals(*table)) {
    std::cerr << "Parquet round trip failed: " << restored_result.status() << '\n';
    return 1;
  }

  arrow::dataset::ParquetFileFormat format;
  if (format.type_name() != "parquet" ||
      !arrow::util::Codec::IsAvailable(arrow::Compression::ZSTD) ||
      !arrow::util::Codec::IsAvailable(arrow::Compression::SNAPPY)) {
    std::cerr << "Dataset format or compression codec is unavailable\n";
    return 1;
  }

  std::cout << "Apache Arrow " << ARROW_VERSION_STRING
            << " C++/Acero/Parquet/Dataset smoke passed\n";
  return 0;
}
