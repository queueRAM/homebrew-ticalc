class Libticables2 < Formula
  desc "TI link cable library"
  homepage "http://lpg.ticalc.org/prj_tilp/"
  url "http://downloads.sourceforge.net/project/tilp/tilp2-linux/tilp2-1.18/libticables2-1.3.5.tar.bz2"
  sha256 "0c6fb6516e72ccab081ddb3aecceff694ed93aec689ddd2edba9c7c7406c4522"
  license "GPL-2.0"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "glib"
  depends_on "libusb"

  patch :DATA

  def install
    system "autoreconf", "-fi"
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--enable-logging",
                          "--enable-libusb10"
    system "make", "install"
  end

  test do
    system "false"
  end
end
__END__
diff --git a/configure.ac b/configure.ac
index f9684ea..2884ba1 100644
--- a/configure.ac
+++ b/configure.ac
@@ -140,6 +140,7 @@ dnl AC_CANONICAL_HOST
 case "$host" in
   i[[3456]]86-*-*bsd*)   ARCH="-D__BSD__ -D__I386__" ;;
   *-*-*bsd*)             ARCH="-D__BSD__" ;;
+  aarch64-apple-darwin*) ARCH="-D__MACOSX__" ;;
   aarch64-*-linux-*)     ARCH="-D__LINUX__" ;;
   alpha*-*-linux-*)      ARCH="-D__ALPHA__ -D__LINUX__" ;;
   alpha*-*-*-*)          ARCH="-D__ALPHA__ -D__LINUX__" ;;
