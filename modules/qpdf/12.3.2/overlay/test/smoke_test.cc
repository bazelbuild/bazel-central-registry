// Smoke test for the @qpdf module: a downstream consumer compiles against the
// public <qpdf/...> headers, links libqpdf plus its zlib/libjpeg_turbo deps,
// and calls into it at run time. Asserting the exact version catches
// wrong-version archive resolution and broken module wiring. Writing an empty
// PDF to a memory buffer exercises the selected crypto provider: QPDFWriter
// generates the trailer /ID with MD5, which dispatches through
// QPDFCryptoProvider, so a provider that failed to register or link fails
// here. No file I/O on purpose: this must also run on Windows CI, where a
// materialized runfiles tree is not guaranteed.

#include <cstdio>
#include <memory>
#include <string>

#include <qpdf/Buffer.hh>
#include <qpdf/QPDF.hh>
#include <qpdf/QPDFWriter.hh>

int main() {
    std::string const& version = QPDF::QPDFVersion();
    if (version != "12.3.2") {
        std::fprintf(stdout, "FAIL: expected version 12.3.2, got: %s\n", version.c_str());
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
