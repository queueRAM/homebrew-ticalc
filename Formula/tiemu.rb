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
diff --git a/src/gui/calc/keynames.c b/src/gui/calc/keynames.c
index eafea0f..b13a9dc 100755
--- a/src/gui/calc/keynames.c
+++ b/src/gui/calc/keynames.c
@@ -136,9 +136,9 @@ const KeyTuple pckeys[] = {
 	{ PCKEY_RETURN, "PCKEY_RETURN" },
 	{ PCKEY_SHIFT_L, "PCKEY_SHIFT_L" },
 	{ PCKEY_CONTROL_L, "PCKEY_CONTROL_L" },
+	{ PCKEY_SHIFT_R, "PCKEY_SHIFT_R" },
 #ifndef __MACOSX__
 /* FIXME: We need the key codes for these on OS X. */
-	{ PCKEY_SHIFT_R, "PCKEY_SHIFT_R" },
 	{ PCKEY_CONTROL_R, "PCKEY_CONTROL_R" },
 #endif
 	{ PCKEY_MENU, "PCKEY_MENU" },
diff --git a/src/gui/calc/pckeys.h b/src/gui/calc/pckeys.h
index a8a7e3e..72b40bc 100644
--- a/src/gui/calc/pckeys.h
+++ b/src/gui/calc/pckeys.h
@@ -339,104 +339,108 @@
 #define PCKEY_OEM_CLEAR 0xFf
 
 #elif defined(__MACOSX__)
-// List manually written by Christian Walther
-#define PCKEY_LBUTTON -2
-#define PCKEY_RBUTTON -2
-#define PCKEY_MBUTTON -2
-#define PCKEY_CANCEL -2
+#define PCKEY_STARTKEY  0x37 // command
+#define PCKEY_MENU      0x3a // option
+#define PCKEY_CONTROL_L 0x3b
+#define PCKEY_SHIFT_L   0x38
+#define PCKEY_SHIFT_R   0x3c
+#define PCKEY_SPACE     0x31
+#define PCKEY_ESCAPE    0x35
+#define PCKEY_TAB       0x30
+#define PCKEY_BACK      0x33
+#define PCKEY_RETURN    0x24
+#define PCKEY_LEFT      0x7b
+#define PCKEY_UP        0x7e
+#define PCKEY_RIGHT     0x7c
+#define PCKEY_DOWN      0x7d
+#define PCKEY_0   0x1d
+#define PCKEY_1   0x12
+#define PCKEY_2   0x13
+#define PCKEY_3   0x14
+#define PCKEY_4   0x15
+#define PCKEY_5   0x17
+#define PCKEY_6   0x16
+#define PCKEY_7   0x1a
+#define PCKEY_8   0x1c
+#define PCKEY_9   0x19
+#define PCKEY_0   0x1d
+#define PCKEY_A   0x00
+#define PCKEY_B   0x0b
+#define PCKEY_C   0x08
+#define PCKEY_D   0x02
+#define PCKEY_E   0x0e
+#define PCKEY_F   0x03
+#define PCKEY_G   0x05
+#define PCKEY_H   0x04
+#define PCKEY_I   0x22
+#define PCKEY_J   0x26
+#define PCKEY_K   0x28
+#define PCKEY_L   0x25
+#define PCKEY_M   0x2e
+#define PCKEY_N   0x2d
+#define PCKEY_O   0x1f
+#define PCKEY_P   0x23
+#define PCKEY_Q   0x0c
+#define PCKEY_R   0x0f
+#define PCKEY_S   0x01
+#define PCKEY_T   0x11
+#define PCKEY_U   0x20
+#define PCKEY_V   0x09
+#define PCKEY_W   0x0d
+#define PCKEY_X   0x07
+#define PCKEY_Y   0x10
+#define PCKEY_Z   0x06
+#define PCKEY_F1  0x7a
+#define PCKEY_F2  0x78
+#define PCKEY_F3  0x63
+#define PCKEY_F4  0x76
+#define PCKEY_F5  0x60
+#define PCKEY_F6  0x61
+#define PCKEY_F7  0x62
+#define PCKEY_F8  0x64
+#define PCKEY_F9  0x65
+#define PCKEY_F10 0x6d
+#define PCKEY_F11 0x6e
+#define PCKEY_F12 0x6f
+#define PCKEY_OEM_COMMA  0x2b
+#define PCKEY_SUBTRACT   0x1b
+#define PCKEY_OEM_PERIOD 0x2f
+#define PCKEY_DIVIDE     0x2c
 
-#define PCKEY_BACK 59
-#define PCKEY_TAB 56
-#define PCKEY_CLEAR 0xff
-#define PCKEY_RETURN 44
-#define PCKEY_SHIFT_L 64
-#define PCKEY_CONTROL_L 0x43
-#define PCKEY_MENU 0x42 //option
-#define PCKEY_PAUSE 121
-#define PCKEY_CAPITAL 65
-#define PCKEY_ESCAPE 61
-#define PCKEY_SPACE 57
-#define PCKEY_PRIOR 124
-#define PCKEY_NEXT 129
-#define PCKEY_END 127
-#define PCKEY_HOME 123
-#define PCKEY_LEFT 0x83
-#define PCKEY_UP 0x86
-#define PCKEY_RIGHT 0x84
-#define PCKEY_DOWN 0x85
-#define PCKEY_SELECT 0xff
-#define PCKEY_PRINT 0xff
-#define PCKEY_EXECUTE 0xff
-#define PCKEY_SNAPSHOT 113
-#define PCKEY_INSERT 122
-#define PCKEY_DELETE 125
-#define PCKEY_HELP 0xff
-#define PCKEY_0 37
-#define PCKEY_1 26
-#define PCKEY_2 27
-#define PCKEY_3 28
-#define PCKEY_4 29
-#define PCKEY_5 31
-#define PCKEY_6 30
-#define PCKEY_7 34
-#define PCKEY_8 36
-#define PCKEY_9 33
-#define PCKEY_A 8
-#define PCKEY_B 19
-#define PCKEY_C 16
-#define PCKEY_D 10
-#define PCKEY_E 22
-#define PCKEY_F 11
-#define PCKEY_G 13
-#define PCKEY_H 12
-#define PCKEY_I 42
-#define PCKEY_J 46
-#define PCKEY_K 48
-#define PCKEY_L 45
-#define PCKEY_M 54
-#define PCKEY_N 53
-#define PCKEY_O 39
-#define PCKEY_P 43
-#define PCKEY_Q 20
-#define PCKEY_R 23
-#define PCKEY_S 9
-#define PCKEY_T 25
-#define PCKEY_U 40
-#define PCKEY_V 17
-#define PCKEY_W 21
-#define PCKEY_X 15
-#define PCKEY_Y 24
-#define PCKEY_Z 14
-#define PCKEY_STARTKEY 0x3f //command
+#define PCKEY_LBUTTON    0xff
+#define PCKEY_RBUTTON    0xff
+#define PCKEY_MBUTTON    0xff
+#define PCKEY_CANCEL     0xff
+#define PCKEY_CLEAR      0xff
+#define PCKEY_PAUSE      0xff
+#define PCKEY_CAPITAL    0xff
+#define PCKEY_PRIOR      0xff
+#define PCKEY_NEXT       0xff
+#define PCKEY_END        0xff
+#define PCKEY_HOME       0xff
+#define PCKEY_SELECT     0xff
+#define PCKEY_PRINT      0xff
+#define PCKEY_EXECUTE    0xff
+#define PCKEY_SNAPSHOT   0xff
+#define PCKEY_INSERT     0xff
+#define PCKEY_DELETE     0xff
+#define PCKEY_HELP       0xff
 #define PCKEY_CONTEXTKEY 0xff
-#define PCKEY_NUMPAD0 90
-#define PCKEY_NUMPAD1 91
-#define PCKEY_NUMPAD2 92
-#define PCKEY_NUMPAD3 93
-#define PCKEY_NUMPAD4 94
-#define PCKEY_NUMPAD5 95
-#define PCKEY_NUMPAD6 96
-#define PCKEY_NUMPAD7 97
-#define PCKEY_NUMPAD8 99
-#define PCKEY_NUMPAD9 100
-#define PCKEY_MULTIPLY 75
-#define PCKEY_ADD 77
-#define PCKEY_SEPARATOR 0xff
-#define PCKEY_SUBTRACT 86
-#define PCKEY_DECIMAL 73
-#define PCKEY_DIVIDE 83
-#define PCKEY_F1 130
-#define PCKEY_F2 128
-#define PCKEY_F3 107
-#define PCKEY_F4 126
-#define PCKEY_F5 104
-#define PCKEY_F6 105
-#define PCKEY_F7 106
-#define PCKEY_F8 108
-#define PCKEY_F9 109
-#define PCKEY_F10 117
-#define PCKEY_F11 111
-#define PCKEY_F12 119
+#define PCKEY_NUMPAD0    0xff
+#define PCKEY_NUMPAD1    0xff
+#define PCKEY_NUMPAD2    0xff
+#define PCKEY_NUMPAD3    0xff
+#define PCKEY_NUMPAD4    0xff
+#define PCKEY_NUMPAD5    0xff
+#define PCKEY_NUMPAD6    0xff
+#define PCKEY_NUMPAD7    0xff
+#define PCKEY_NUMPAD8    0xff
+#define PCKEY_NUMPAD9    0xff
+#define PCKEY_OEM_MINUS  0xff
+#define PCKEY_MULTIPLY   0xff
+#define PCKEY_ADD        0xff
+#define PCKEY_SEPARATOR  0xff
+#define PCKEY_DECIMAL    0xff
 #define PCKEY_F13 0xff
 #define PCKEY_F14 0xff
 #define PCKEY_F15 0xff
@@ -449,23 +453,20 @@
 #define PCKEY_F22 0xff
 #define PCKEY_F23 0xff
 #define PCKEY_F24 0xff
-#define PCKEY_NUMLOCK 79
-#define PCKEY_OEM_SCROLL 115
-#define PCKEY_OEM_1 0x31
-#define PCKEY_OEM_PLUS 0x20
-#define PCKEY_OEM_COMMA 51
-#define PCKEY_OEM_MINUS 0x23
-#define PCKEY_OEM_PERIOD 55
-#define PCKEY_OEM_2 0x34
-#define PCKEY_OEM_3 0x12
-#define PCKEY_OEM_4 0x29
-#define PCKEY_OEM_5 0x32
-#define PCKEY_OEM_6 0x26
-#define PCKEY_OEM_7 0x2f
+#define PCKEY_NUMLOCK 0xff
+#define PCKEY_OEM_SCROLL 0xff
+#define PCKEY_OEM_1 0xff
+#define PCKEY_OEM_PLUS 0xff
+#define PCKEY_OEM_2 0xff
+#define PCKEY_OEM_3 0xff
+#define PCKEY_OEM_4 0xff
+#define PCKEY_OEM_5 0xff
+#define PCKEY_OEM_6 0xff
+#define PCKEY_OEM_7 0xff
 #define PCKEY_OEM_8 0xff
 #define PCKEY_ICO_F17 0xff
 #define PCKEY_ICO_F18 0xff
-#define PCKEY_OEM102 58
+#define PCKEY_OEM102 0xff
 #define PCKEY_ICO_HELP 0xff
 #define PCKEY_ICO_00 0xff
 #define PCKEY_ICO_CLEAR 0xff
