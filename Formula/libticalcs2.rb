class Libticalcs2 < Formula
  desc "TI calcs library"
  homepage "http://lpg.ticalc.org/prj_tilp/"
  url "http://downloads.sourceforge.net/project/tilp/tilp2-linux/tilp2-1.18/libticalcs2-1.1.9.tar.bz2"
  sha256 "76780788bc309b647f97513d38dd5f01611c335a72855e0bd10c7bdbf2e38921"
  license "GPL-2.0"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "libticables2"
  depends_on "libtifiles2"

  def install
    system "autoreconf", "-fi"
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system "false"
  end
end
