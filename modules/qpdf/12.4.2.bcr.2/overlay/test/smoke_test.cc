// Writing a PDF computes its trailer /ID with MD5 through the selected crypto provider. No file I/O, so it runs on
// Windows CI too.

#include <cstdio>
#include <memory>
#include <string>

#include <qpdf/Buffer.hh>
#include <qpdf/QPDF.hh>
#include <qpdf/QPDFWriter.hh>

int main() {
    std::string const& version = QPDF::QPDFVersion();
    if (version != "12.4.2") {
        std::fprintf(stdout, "FAIL: expected version 12.4.2, got: %s\n", version.c_str());
        return 1;
    }
    QPDF pdf;
    pdf.emptyPDF();
    QPDFWriter writer(pdf);
    writer.setOutputMemory();
    writer.write();
    std::shared_ptr<Buffer> buf = writer.getBufferSharedPointer();
    if (buf->getSize() < 8 ||
        std::string(reinterpret_cast<char const*>(buf->getBuffer()), 5) != "%PDF-") {
        std::fputs("FAIL: written buffer does not start with %PDF-\n", stdout);
        return 1;
    }
    return 0;
}
