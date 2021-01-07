class Tiemu < Formula
  desc "TiEmu emulates Texas Instruments calculators TI-89/92/92+/V200PLT (no GDB)."
  homepage "http://lpg.ticalc.org/prj_tiemu/"
  url "http://download.sourceforge.net/project/gtktiemu/tiemu-linux/TIEmu%203.03/tiemu-3.03-nogdb.tar.gz"
  sha256 "92d2830842278a8df29ab0717f5b89e06b34e88a50c073fe10ff9e6855b8a592"
  license "GPL-2.0"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "libglade"
  depends_on "libticalcs2"
  depends_on "sdl"

  patch :DATA

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--without-kde",
                          "--disable-debugger",
                          "--disable-gdb",
                          "--disable-sdltest",
                          "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    system "false"
  end
end
__END__
diff -aur tiemu-3.03.orig/src/core/uae/newcpu.c tiemu-3.03/src/core/uae/newcpu.c
--- tiemu-3.03.orig/src/core/uae/newcpu.c	2008-05-25 06:08:41.000000000 -0700
+++ tiemu-3.03/src/core/uae/newcpu.c	2021-01-05 20:15:47.000000000 -0800
@@ -30,6 +30,8 @@
 extern const char *symfile;
 #endif /* CYGNUS_SIM */
 #define FLOATFORMAT_H /* don't include glib.h in romcalls.h */
+#include "romcalls.h"
+#include "handles.h"
 // tiemu end
 
 /* Opcode of faulting instruction */
diff -aur tiemu-3.03.orig/src/core/uae/sysdeps.h tiemu-3.03/src/core/uae/sysdeps.h
--- tiemu-3.03.orig/src/core/uae/sysdeps.h	2007-06-23 22:05:05.000000000 -0700
+++ tiemu-3.03/src/core/uae/sysdeps.h	2021-01-05 20:17:19.000000000 -0800
@@ -136,13 +136,6 @@
 #ifdef __GNUC__
 #define ENUMDECL typedef enum
 #define ENUMNAME(name) name
-
-/* While we're here, make abort more useful.  */
-#define abort() \
-  do { \
-    fprintf (stderr, "UAE: Internal error; file %s, line %d\n", __FILE__, __LINE__); \
-    (abort) (); \
-} while (0)
 #else
 #define ENUMDECL enum
 #define ENUMNAME(name) ; typedef int name
diff -aur tiemu-3.03.orig/src/gui/about.c tiemu-3.03/src/gui/about.c
--- tiemu-3.03.orig/src/gui/about.c	2007-04-15 01:29:34.000000000 -0700
+++ tiemu-3.03/src/gui/about.c	2021-01-05 20:21:03.000000000 -0800
@@ -103,7 +103,7 @@
 	dlg = GTK_ABOUT_DIALOG(widget);
 	pix = create_pixbuf("logo.xpm");
 
-	gtk_about_dialog_set_name(dlg, "TiEmu - Ti Emulator - ");
+	gtk_about_dialog_set_program_name(dlg, "TiEmu - Ti Emulator - ");
 	gtk_about_dialog_set_version(dlg, TIEMU_VERSION);
 	gtk_about_dialog_set_comments(dlg, version);
 	gtk_about_dialog_set_copyright(dlg, "Copyright (c) 1999-2007 The TiEmu Team");
diff -aur tiemu-3.03.orig/src/gui/calc/calc.c tiemu-3.03/src/gui/calc/calc.c
--- tiemu-3.03.orig/src/gui/calc/calc.c	2007-12-16 07:29:16.000000000 -0800
+++ tiemu-3.03/src/gui/calc/calc.c	2021-01-05 20:12:20.000000000 -0800
@@ -313,7 +313,7 @@
 {
     gdk_draw_pixmap(
         widget->window,
-		widget->style->fg_gc[GTK_WIDGET_STATE (widget)],
+		widget->style->fg_gc[gtk_widget_get_state (widget)],
 		pixmap,
 		event->area.x, event->area.y,
 		event->area.x, event->area.y,
@@ -586,7 +586,7 @@
 
     // Install LCD refresh: 100 FPS (10 ms)
     tid = g_timeout_add((params.lcd_rate == -1) ? 50 : params.lcd_rate, 
-		(GtkFunction)hid_refresh, NULL);
+		(GSourceFunc)hid_refresh, NULL);
 
 	explicit_destroy = 0;
 	gtk_widget_show(main_wnd);	// show wnd here
@@ -640,7 +640,7 @@
 	g_source_remove(tid);
 
 	tid = g_timeout_add((params.lcd_rate == -1) ? 50 : params.lcd_rate, 
-		(GtkFunction)hid_refresh, NULL);
+		(GSourceFunc)hid_refresh, NULL);
 }
 
 int hid_switch_with_skin(void)
diff -aur tiemu-3.03.orig/src/gui/calc/popup.c tiemu-3.03/src/gui/calc/popup.c
--- tiemu-3.03.orig/src/gui/calc/popup.c	2009-05-08 13:43:47.000000000 -0700
+++ tiemu-3.03/src/gui/calc/popup.c	2021-01-05 20:12:20.000000000 -0800
@@ -26,7 +26,9 @@
 #  include <config.h>
 #endif
 
+#undef GTK_DISABLE_DEPRECATED
 #include <gtk/gtk.h>
+#define GTK_DISABLE_DEPRECATED
 #include <glade/glade.h>
 #include <stdlib.h>
 #include <string.h>
diff -aur tiemu-3.03.orig/src/gui/calc/screen.c tiemu-3.03/src/gui/calc/screen.c
--- tiemu-3.03.orig/src/gui/calc/screen.c	2006-11-06 09:18:51.000000000 -0800
+++ tiemu-3.03/src/gui/calc/screen.c	2021-01-05 20:12:20.000000000 -0800
@@ -187,7 +187,7 @@
 	skin_infos.image = gdk_pixbuf_scale_simple(skin_infos.raw, wr.wr.w, wr.wr.h, GDK_INTERP_NEAREST);
 
 	// and draw image into pixmap (next, into window on expose event)
-    gdk_draw_pixbuf(pixmap, main_wnd->style->fg_gc[GTK_WIDGET_STATE(main_wnd)],
+    gdk_draw_pixbuf(pixmap, main_wnd->style->fg_gc[gtk_widget_get_state(main_wnd)],
 		  skin_infos.image, 0, 0, 0, 0, -1, -1, GDK_RGB_DITHER_NONE, 0, 0);
 	gdk_window_invalidate_rect(main_wnd->window, &wr.gr, FALSE);
 }
@@ -204,7 +204,7 @@
 		gdk_pixbuf_scale_simple(skin_infos.raw, sr.w, sr.h, GDK_INTERP_NEAREST);
 
 	// and draw
-	gdk_draw_pixbuf(pixmap, main_wnd->style->fg_gc[GTK_WIDGET_STATE(main_wnd)],
+	gdk_draw_pixbuf(pixmap, main_wnd->style->fg_gc[gtk_widget_get_state(main_wnd)],
 		  skin_infos.image, ls.x, ls.y, lr.x, lr.y, lr.w, lr.h, GDK_RGB_DITHER_NONE, 0, 0);
 	gtk_widget_queue_draw_area(area, lr.x, lr.y, lr.w, lr.h);
 }
@@ -324,7 +324,7 @@
 			skin_infos.image = gdk_pixbuf_scale_simple(lcd, lr.w, lr.h, GDK_INTERP_NEAREST);
 
 			// and draw image into pixmap (next, into window on expose event)
-			gdk_draw_pixbuf(pixmap, main_wnd->style->fg_gc[GTK_WIDGET_STATE(main_wnd)],
+			gdk_draw_pixbuf(pixmap, main_wnd->style->fg_gc[gtk_widget_get_state(main_wnd)],
 			 skin_infos.image, src.x, src.y, lr.x, lr.y, src.w, src.h,
 			  GDK_RGB_DITHER_NONE, 0, 0);
 			gtk_widget_queue_draw_area(area, lr.x, lr.y, src.w, src.h);
@@ -332,7 +332,7 @@
 		else
 		{
 			// and draw image into pixmap (next, into window on expose event)
-			gdk_draw_pixbuf(pixmap, main_wnd->style->fg_gc[GTK_WIDGET_STATE(main_wnd)],
+			gdk_draw_pixbuf(pixmap, main_wnd->style->fg_gc[gtk_widget_get_state(main_wnd)],
 			  lcd_mem, src.x, src.y, lr.x, lr.y, src.w, src.h,
 			  GDK_RGB_DITHER_NONE, 0, 0);
 			gtk_widget_queue_draw_area(area, lr.x, lr.y, src.w, src.h);
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_all.c tiemu-3.03/src/gui/debugger/dbg_all.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_all.c	2009-05-08 03:56:40.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_all.c	2021-01-05 20:12:20.000000000 -0800
@@ -90,21 +90,21 @@
 {	
 	WND_TMR_START();
 
-	if(options3.dbg_dock || GTK_WIDGET_VISIBLE(dbgw.regs))
+	if(options3.dbg_dock || gtk_widget_get_visible(dbgw.regs))
 		dbgregs_refresh_window();
-	if(options3.dbg_dock || GTK_WIDGET_VISIBLE(dbgw.mem))
+	if(options3.dbg_dock || gtk_widget_get_visible(dbgw.mem))
 		dbgmem_refresh_window();
-	if(options3.dbg_dock || GTK_WIDGET_VISIBLE(dbgw.bkpts))
+	if(options3.dbg_dock || gtk_widget_get_visible(dbgw.bkpts))
 		dbgbkpts_refresh_window();
-	if(options3.dbg_dock || GTK_WIDGET_VISIBLE(dbgw.pclog))
+	if(options3.dbg_dock || gtk_widget_get_visible(dbgw.pclog))
 		dbgpclog_refresh_window();
-	if(options3.dbg_dock || GTK_WIDGET_VISIBLE(dbgw.code))
+	if(options3.dbg_dock || gtk_widget_get_visible(dbgw.code))
 		dbgcode_refresh_window();
-    if(options3.dbg_dock || GTK_WIDGET_VISIBLE(dbgw.stack))
+    if(options3.dbg_dock || gtk_widget_get_visible(dbgw.stack))
 		dbgstack_refresh_window();
-	if(options3.dbg_dock || GTK_WIDGET_VISIBLE(dbgw.heap))
+	if(options3.dbg_dock || gtk_widget_get_visible(dbgw.heap))
 		dbgheap_refresh_window();
-	if(options3.dbg_dock || GTK_WIDGET_VISIBLE(dbgw.iop))
+	if(options3.dbg_dock || gtk_widget_get_visible(dbgw.iop))
 		dbgiop_refresh_window();
 
 	WND_TMR_STOP("Debugger Refresh Time");
@@ -163,7 +163,7 @@
 	gtk_debugger_refresh();
 
 	// enable the debugger if GDB disabled it
-	if (!options3.dbg_dock && !GTK_WIDGET_SENSITIVE(dbgw.regs))
+	if (!options3.dbg_dock && !gtk_widget_get_sensitive(dbgw.regs))
 		gtk_debugger_enable();
 
 	// handle automatic debugging requests
@@ -180,7 +180,7 @@
 
 			ti68k_bkpt_get_pgmentry_offset(id, &handle, &offset);
 			ti68k_bkpt_del_pgmentry(handle);
-			if(options3.dbg_dock || GTK_WIDGET_VISIBLE(dbgw.bkpts))
+			if(options3.dbg_dock || gtk_widget_get_visible(dbgw.bkpts))
 				dbgbkpts_refresh_window();
 
 			delete_command(NULL, 0);
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_bkpts.c tiemu-3.03/src/gui/debugger/dbg_bkpts.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_bkpts.c	2009-05-06 12:48:47.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_bkpts.c	2021-01-05 20:12:20.000000000 -0800
@@ -388,7 +388,7 @@
 		gtk_window_iconify(GTK_WINDOW(wnd));
 #endif
 
-	if(!GTK_WIDGET_VISIBLE(dbgw.bkpts) && !options3.bkpts.closed)
+	if(!gtk_widget_get_visible(dbgw.bkpts) && !options3.bkpts.closed)
 		gtk_widget_show(wnd);
 
 	return wnd;
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_code.c tiemu-3.03/src/gui/debugger/dbg_code.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_code.c	2009-05-06 12:48:47.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_code.c	2021-01-05 20:12:20.000000000 -0800
@@ -1117,7 +1117,7 @@
 
 int dbgcode_quit_enabled(void)
 {
-	return GTK_WIDGET_SENSITIVE(mi.m8);
+	return gtk_widget_get_sensitive(mi.m8);
 }
 
 static int close_debugger_wrapper(gpointer data)
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_dock.c tiemu-3.03/src/gui/debugger/dbg_dock.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_dock.c	2008-05-26 09:48:30.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_dock.c	2021-01-05 20:12:20.000000000 -0800
@@ -151,22 +151,22 @@
 
 void dbgdock_show_all(int all)
 {
-	if(!GTK_WIDGET_VISIBLE(dbgw.dock) && all)
+	if(!gtk_widget_get_visible(dbgw.dock) && all)
         gtk_widget_show(dbgw.dock);
 
-	if(GTK_WIDGET_VISIBLE(dbgw.iop))
+	if(gtk_widget_get_visible(dbgw.iop))
         gtk_window_iconify(GTK_WINDOW(dbgw.iop));
-	if(GTK_WIDGET_VISIBLE(dbgw.pclog))
+	if(gtk_widget_get_visible(dbgw.pclog))
         gtk_window_iconify(GTK_WINDOW(dbgw.pclog));
 }
 
 void dbgdock_hide_all(int all)
 {
-	if(GTK_WIDGET_VISIBLE(dbgw.dock) && all)
+	if(gtk_widget_get_visible(dbgw.dock) && all)
         gtk_widget_hide(dbgw.dock);
 
-    if(GTK_WIDGET_VISIBLE(dbgw.pclog))
+    if(gtk_widget_get_visible(dbgw.pclog))
         gtk_widget_hide(dbgw.pclog);
-	if(GTK_WIDGET_VISIBLE(dbgw.iop))
+	if(gtk_widget_get_visible(dbgw.iop))
         gtk_widget_hide(dbgw.iop);
 }
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_heap.c tiemu-3.03/src/gui/debugger/dbg_heap.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_heap.c	2009-05-06 12:48:47.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_heap.c	2021-01-05 20:12:20.000000000 -0800
@@ -171,7 +171,7 @@
 		gtk_window_iconify(GTK_WINDOW(dbgw.heap));
 #endif
 
-	if(!GTK_WIDGET_VISIBLE(dbgw.heap) && !options3.heap.closed)
+	if(!gtk_widget_get_visible(dbgw.heap) && !options3.heap.closed)
 		gtk_widget_show(dbgw.heap);
 
 	return dbgw.heap;
@@ -277,3 +277,4 @@
 {
 	dbgmem_add_tab(value);
 }
+
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_iop.c tiemu-3.03/src/gui/debugger/dbg_iop.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_iop.c	2009-05-02 12:46:04.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_iop.c	2021-01-05 20:12:20.000000000 -0800
@@ -455,7 +455,7 @@
 		gtk_window_iconify(GTK_WINDOW(dbgw.iop));
 #endif
     
-	if(!GTK_WIDGET_VISIBLE(dbgw.iop) && !options3.iop.closed)
+	if(!gtk_widget_get_visible(dbgw.iop) && !options3.iop.closed)
 		gtk_widget_show(dbgw.iop);
 
 	return dbgw.iop;
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_mem.c tiemu-3.03/src/gui/debugger/dbg_mem.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_mem.c	2009-05-06 12:48:47.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_mem.c	2021-01-05 20:22:24.000000000 -0800
@@ -435,7 +435,7 @@
 		gtk_window_iconify(GTK_WINDOW(dbgw.mem));
 #endif
 
-	if(!GTK_WIDGET_VISIBLE(dbgw.mem) && !options3.mem.closed)
+	if(!gtk_widget_get_visible(dbgw.mem) && !options3.mem.closed)
 		gtk_widget_show(dbgw.mem);
 
     return dbgw.mem;
@@ -551,7 +551,7 @@
 
 	menu = gtk_menu_new();
 	g_object_set_data_full(G_OBJECT(menu), "memmap_menu",
-			       gtk_widget_ref(menu),
+			       g_object_ref(menu),
 			       (GDestroyNotify)g_object_unref);
 
 	// (re)load mem map
@@ -574,7 +574,7 @@
 
 		item = gtk_menu_item_new_with_label(label);
 		g_object_set_data_full(G_OBJECT(menu), "c_drive",
-					   gtk_widget_ref(item),
+					   g_object_ref(item),
 					   (GDestroyNotify)g_object_unref);
 		gtk_widget_show(item);
 
@@ -605,7 +605,7 @@
 
 GLADE_CB void
 on_notebook1_switch_page               (GtkNotebook     *notebook,
-                                        GtkNotebookPage *page,
+                                        gpointer         page,
                                         guint            page_num,
                                         gpointer         user_data)
 {
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_pclog.c tiemu-3.03/src/gui/debugger/dbg_pclog.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_pclog.c	2009-05-02 12:46:04.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_pclog.c	2021-01-05 20:12:20.000000000 -0800
@@ -163,7 +163,7 @@
 		gtk_window_iconify(GTK_WINDOW(dbgw.pclog));
 #endif
 
-	if(!GTK_WIDGET_VISIBLE(dbgw.pclog) && !options3.pclog.closed)
+	if(!gtk_widget_get_visible(dbgw.pclog) && !options3.pclog.closed)
 		gtk_widget_show(dbgw.pclog);
 
 	return dbgw.pclog;
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_regs.c tiemu-3.03/src/gui/debugger/dbg_regs.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_regs.c	2009-05-06 12:48:47.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_regs.c	2021-01-05 20:12:20.000000000 -0800
@@ -302,7 +302,7 @@
 		gtk_window_iconify(GTK_WINDOW(dbgw.regs));
 #endif
 
-	if(!GTK_WIDGET_VISIBLE(dbgw.regs) && !options3.regs.closed)
+	if(!gtk_widget_get_visible(dbgw.regs) && !options3.regs.closed)
 		gtk_widget_show(dbgw.regs);
 
 	return dbgw.regs;
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_romcall.c tiemu-3.03/src/gui/debugger/dbg_romcall.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_romcall.c	2007-07-05 04:36:10.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_romcall.c	2021-01-05 20:12:20.000000000 -0800
@@ -29,7 +29,9 @@
 #  include <config.h>
 #endif
 
-#include <gtk/gtk.h>
+#undef GTK_DISABLE_DEPRECATED
+ #include <gtk/gtk.h>
+#define GTK_DISABLE_DEPRECATED
 #include <glade/glade.h>
 #include <string.h>
 
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_stack.c tiemu-3.03/src/gui/debugger/dbg_stack.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_stack.c	2009-05-06 12:48:47.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_stack.c	2021-01-05 20:12:20.000000000 -0800
@@ -197,7 +197,7 @@
 		gtk_window_iconify(GTK_WINDOW(dbgw.stack));
 #endif
 
-	if(!GTK_WIDGET_VISIBLE(dbgw.stack) && !options3.stack.closed)
+	if(!gtk_widget_get_visible(dbgw.stack) && !options3.stack.closed)
 		gtk_widget_show(dbgw.stack);
 
 	return dbgw.stack;
@@ -427,3 +427,4 @@
 {
 	dbgmem_add_tab(value);
 }
+
diff -aur tiemu-3.03.orig/src/gui/debugger/dbg_wnds.c tiemu-3.03/src/gui/debugger/dbg_wnds.c
--- tiemu-3.03.orig/src/gui/debugger/dbg_wnds.c	2009-05-07 00:18:02.000000000 -0700
+++ tiemu-3.03/src/gui/debugger/dbg_wnds.c	2021-01-05 20:12:20.000000000 -0800
@@ -74,21 +74,21 @@
 	if(options3.dbg_dock)
 		return;
 
-    if(GTK_WIDGET_VISIBLE(dbgw.regs))
+    if(gtk_widget_get_visible(dbgw.regs))
         gtk_window_iconify(GTK_WINDOW(dbgw.regs));
-    if(GTK_WIDGET_VISIBLE(dbgw.bkpts))
+    if(gtk_widget_get_visible(dbgw.bkpts))
         gtk_window_iconify(GTK_WINDOW(dbgw.bkpts));
-    if(GTK_WIDGET_VISIBLE(dbgw.mem))
+    if(gtk_widget_get_visible(dbgw.mem))
         gtk_window_iconify(GTK_WINDOW(dbgw.mem));
-    if(GTK_WIDGET_VISIBLE(dbgw.pclog))
+    if(gtk_widget_get_visible(dbgw.pclog))
         gtk_window_iconify(GTK_WINDOW(dbgw.pclog));
-    if(GTK_WIDGET_VISIBLE(dbgw.code) & all)
+    if(gtk_widget_get_visible(dbgw.code) & all)
         gtk_window_iconify(GTK_WINDOW(dbgw.code));
-    if(GTK_WIDGET_VISIBLE(dbgw.stack))
+    if(gtk_widget_get_visible(dbgw.stack))
         gtk_window_iconify(GTK_WINDOW(dbgw.stack));
-	if(GTK_WIDGET_VISIBLE(dbgw.heap))
+	if(gtk_widget_get_visible(dbgw.heap))
         gtk_window_iconify(GTK_WINDOW(dbgw.heap));
-	if(GTK_WIDGET_VISIBLE(dbgw.iop))
+	if(gtk_widget_get_visible(dbgw.iop))
         gtk_window_iconify(GTK_WINDOW(dbgw.iop));
 }
 
@@ -98,21 +98,21 @@
 	if(options3.dbg_dock)
 		return;
 
-    if(GTK_WIDGET_VISIBLE(dbgw.regs))
+    if(gtk_widget_get_visible(dbgw.regs))
         gtk_window_deiconify(GTK_WINDOW(dbgw.regs));
-    if(GTK_WIDGET_VISIBLE(dbgw.bkpts))
+    if(gtk_widget_get_visible(dbgw.bkpts))
         gtk_window_deiconify(GTK_WINDOW(dbgw.bkpts));
-    if(GTK_WIDGET_VISIBLE(dbgw.mem))
+    if(gtk_widget_get_visible(dbgw.mem))
         gtk_window_deiconify(GTK_WINDOW(dbgw.mem));
-    if(GTK_WIDGET_VISIBLE(dbgw.pclog))
+    if(gtk_widget_get_visible(dbgw.pclog))
         gtk_window_deiconify(GTK_WINDOW(dbgw.pclog));
-    if(GTK_WIDGET_VISIBLE(dbgw.code) & all)
+    if(gtk_widget_get_visible(dbgw.code) & all)
         gtk_window_deiconify(GTK_WINDOW(dbgw.code));
-    if(GTK_WIDGET_VISIBLE(dbgw.stack))
+    if(gtk_widget_get_visible(dbgw.stack))
         gtk_window_deiconify(GTK_WINDOW(dbgw.stack));
-	if(GTK_WIDGET_VISIBLE(dbgw.heap))
+	if(gtk_widget_get_visible(dbgw.heap))
         gtk_window_deiconify(GTK_WINDOW(dbgw.heap));
-	if(GTK_WIDGET_VISIBLE(dbgw.iop))
+	if(gtk_widget_get_visible(dbgw.iop))
         gtk_window_deiconify(GTK_WINDOW(dbgw.iop));
 }
 
@@ -122,21 +122,21 @@
     if(options3.dbg_dock)
 		return;
 
-    if(!GTK_WIDGET_VISIBLE(dbgw.regs))
+    if(!gtk_widget_get_visible(dbgw.regs))
         gtk_widget_show(dbgw.regs);
-    if(!GTK_WIDGET_VISIBLE(dbgw.bkpts))
+    if(!gtk_widget_get_visible(dbgw.bkpts))
         gtk_widget_show(dbgw.bkpts);
-    if(!GTK_WIDGET_VISIBLE(dbgw.mem))
+    if(!gtk_widget_get_visible(dbgw.mem))
         gtk_widget_show(dbgw.mem);
-    if(!GTK_WIDGET_VISIBLE(dbgw.pclog))
+    if(!gtk_widget_get_visible(dbgw.pclog))
         gtk_widget_show(dbgw.pclog);
-    if(!GTK_WIDGET_VISIBLE(dbgw.code) && all)
+    if(!gtk_widget_get_visible(dbgw.code) && all)
         gtk_widget_show(dbgw.code);
-    if(!GTK_WIDGET_VISIBLE(dbgw.stack))
+    if(!gtk_widget_get_visible(dbgw.stack))
         gtk_widget_show(dbgw.stack);
-	if(!GTK_WIDGET_VISIBLE(dbgw.heap))
+	if(!gtk_widget_get_visible(dbgw.heap))
         gtk_widget_show(dbgw.heap);
-	if(!GTK_WIDGET_VISIBLE(dbgw.iop))
+	if(!gtk_widget_get_visible(dbgw.iop))
         gtk_widget_show(dbgw.iop);
 }
 
@@ -146,21 +146,21 @@
     if(options3.dbg_dock)
 		return;
 
-    if(GTK_WIDGET_VISIBLE(dbgw.regs))
+    if(gtk_widget_get_visible(dbgw.regs))
         gtk_widget_hide(dbgw.regs);
-    if(GTK_WIDGET_VISIBLE(dbgw.bkpts))
+    if(gtk_widget_get_visible(dbgw.bkpts))
         gtk_widget_hide(dbgw.bkpts);
-    if(GTK_WIDGET_VISIBLE(dbgw.mem))
+    if(gtk_widget_get_visible(dbgw.mem))
         gtk_widget_hide(dbgw.mem);
-    if(GTK_WIDGET_VISIBLE(dbgw.pclog))
+    if(gtk_widget_get_visible(dbgw.pclog))
         gtk_widget_hide(dbgw.pclog);
-    if(GTK_WIDGET_VISIBLE(dbgw.code) && all)
+    if(gtk_widget_get_visible(dbgw.code) && all)
         gtk_widget_hide(dbgw.code);
-    if(GTK_WIDGET_VISIBLE(dbgw.stack))
+    if(gtk_widget_get_visible(dbgw.stack))
         gtk_widget_hide(dbgw.stack);
-	if(GTK_WIDGET_VISIBLE(dbgw.heap))
+	if(gtk_widget_get_visible(dbgw.heap))
         gtk_widget_hide(dbgw.heap);
-	if(GTK_WIDGET_VISIBLE(dbgw.iop))
+	if(gtk_widget_get_visible(dbgw.iop))
         gtk_widget_hide(dbgw.iop);
 }
 
@@ -338,7 +338,7 @@
 	if(!options3.dbg_dock)
 	{
 		g_signal_handlers_block_by_func(GTK_OBJECT(item), on_registers1_activate, NULL);
-		gtk_check_menu_item_set_active(item, GTK_WIDGET_VISIBLE(dbgw.regs));
+		gtk_check_menu_item_set_active(item, gtk_widget_get_visible(dbgw.regs));
 		g_signal_handlers_unblock_by_func(GTK_OBJECT(item), on_registers1_activate, NULL);
 	}
 	else
@@ -350,7 +350,7 @@
 	if(!options3.dbg_dock)
 	{
 		g_signal_handlers_block_by_func(GTK_OBJECT(item), on_breakpoints1_activate, NULL);
-		gtk_check_menu_item_set_active(item, GTK_WIDGET_VISIBLE(dbgw.bkpts));
+		gtk_check_menu_item_set_active(item, gtk_widget_get_visible(dbgw.bkpts));
 		g_signal_handlers_unblock_by_func(GTK_OBJECT(item), on_breakpoints1_activate, NULL);
 	}
 	else
@@ -362,7 +362,7 @@
 	if(!options3.dbg_dock)
 	{
 		g_signal_handlers_block_by_func(GTK_OBJECT(item), on_memory1_activate, NULL);
-		gtk_check_menu_item_set_active(item, GTK_WIDGET_VISIBLE(dbgw.mem));
+		gtk_check_menu_item_set_active(item, gtk_widget_get_visible(dbgw.mem));
 		g_signal_handlers_unblock_by_func(GTK_OBJECT(item), on_memory1_activate, NULL);
 	}
 	else
@@ -372,7 +372,7 @@
     elt = g_list_nth(list, 3);
     item = GTK_CHECK_MENU_ITEM(elt->data);
     g_signal_handlers_block_by_func(GTK_OBJECT(item), on_pc_log1_activate, NULL);
-    gtk_check_menu_item_set_active(item, GTK_WIDGET_VISIBLE(dbgw.pclog));
+    gtk_check_menu_item_set_active(item, gtk_widget_get_visible(dbgw.pclog));
     g_signal_handlers_unblock_by_func(GTK_OBJECT(item), on_pc_log1_activate, NULL);
 
     // stack
@@ -381,7 +381,7 @@
 	if(!options3.dbg_dock)
 	{
 		g_signal_handlers_block_by_func(GTK_OBJECT(item), on_stack_frame1_activate, NULL);
-		gtk_check_menu_item_set_active(item, GTK_WIDGET_VISIBLE(dbgw.stack));
+		gtk_check_menu_item_set_active(item, gtk_widget_get_visible(dbgw.stack));
 		g_signal_handlers_unblock_by_func(GTK_OBJECT(item), on_stack_frame1_activate, NULL);
 	}
 	else
@@ -393,7 +393,7 @@
 	if(!options3.dbg_dock)
 	{
 		g_signal_handlers_block_by_func(GTK_OBJECT(item), on_heap_frame1_activate, NULL);
-		gtk_check_menu_item_set_active(item, GTK_WIDGET_VISIBLE(dbgw.heap));
+		gtk_check_menu_item_set_active(item, gtk_widget_get_visible(dbgw.heap));
 		g_signal_handlers_unblock_by_func(GTK_OBJECT(item), on_heap_frame1_activate, NULL);
 	}
 	else
@@ -403,7 +403,7 @@
 	elt = g_list_nth(list, 6);
     item = GTK_CHECK_MENU_ITEM(elt->data);
     g_signal_handlers_block_by_func(GTK_OBJECT(item), on_ioports_frame1_activate, NULL);
-    gtk_check_menu_item_set_active(item, GTK_WIDGET_VISIBLE(dbgw.iop));
+    gtk_check_menu_item_set_active(item, gtk_widget_get_visible(dbgw.iop));
     g_signal_handlers_unblock_by_func(GTK_OBJECT(item), on_ioports_frame1_activate, NULL);
 
 	// dock/multi mode
diff -aur tiemu-3.03.orig/src/gui/filesel.c tiemu-3.03/src/gui/filesel.c
--- tiemu-3.03.orig/src/gui/filesel.c	2007-12-16 07:54:33.000000000 -0800
+++ tiemu-3.03/src/gui/filesel.c	2021-01-05 20:12:20.000000000 -0800
@@ -41,7 +41,9 @@
 
 #include <stdio.h>
 #include <stdlib.h>
+#undef GTK_DISABLE_DEPRECATED
 #include <gtk/gtk.h>
+#define GTK_DISABLE_DEPRECATED
 #include <string.h>
 
 #ifdef __WIN32__
