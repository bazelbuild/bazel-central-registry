import com.google.media.codecs.ultrahdr.UltraHDRCommon;
import com.google.media.codecs.ultrahdr.UltraHDRDecoder;
import com.google.media.codecs.ultrahdr.UltraHDREncoder;

public class JniTest {
    public static void main(String[] args) throws Exception {
        if (!"v2.0.2".equals(UltraHDRCommon.getVersionString())) {
            throw new AssertionError("Unexpected native library version");
        }

        try (UltraHDREncoder encoder = new UltraHDREncoder();
             UltraHDRDecoder decoder = new UltraHDRDecoder()) {
            if (encoder == null || decoder == null) throw new AssertionError();
        }
    }
}
