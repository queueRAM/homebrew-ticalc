class Vasm < Formula
  desc "Portable and retargetable 6502 6800 arm c16x jagrisc m68k pdp11 ppc test tr3200 vidcore x86 z80 assembler"
  homepage "http://sun.hasenbraten.de/vasm/"
  url "http://phoenix.owl.de/tags/vasm1_8j.tar.gz"
  version "1.8j"
  sha256 "8b8b78091d82a92769778b2964e64c4fb98e969b46d65708dcf88f6957072676"
  license "custom"

  def install
    cpu_list = %w(6502 6800 arm c16x jagrisc m68k pdp11 ppc test tr3200 vidcore x86 z80)
    syntax_list = %w(std madmac mot oldstyle)
    cpu_list.each do |cpu|
      syntax_list.each do |syntax|
        system "make", "CPU=#{cpu}", "SYNTAX=#{syntax}"
        bin.install "vasm#{cpu}_#{syntax}"
      end
    end
    bin.install "vobjdump"
  end

  test do
    system "false"
  end
end
