/* window.vala
 *
 * Copyright 2021 Alex
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;
namespace Txtreader {
	[GtkTemplate (ui = "/kaa/kalexal/TXTReader/window.ui")]
	public class Window : Gtk.ApplicationWindow {
	    [GtkChild]
		unowned Stack stack;
		[GtkChild]
        unowned ScrolledWindow list_page;
        [GtkChild]
        unowned ScrolledWindow read_page;
        [GtkChild]
        unowned Gtk.ListStore list_store;
        [GtkChild]
        unowned TreeView tree_view;
        [GtkChild]
        unowned TextView text_view;
        [GtkChild]
        unowned Button back_button;
        [GtkChild]
        unowned Button add_button;
        [GtkChild]
        unowned Button delete_button;
        [GtkChild]
        unowned Button read_button;
        private GLib.File current_file;
        private List<string> list;
        private string directory_path;
        private string item;
		public Window (Gtk.Application app) {
			Object (application: app);
			set_widget_visible(back_button,false);
            back_button.clicked.connect(on_back_clicked);
            add_button.clicked.connect(on_add_clicked);
            delete_button.clicked.connect(on_delete_clicked);
            read_button.clicked.connect(on_read_clicked);
            tree_view.cursor_changed.connect(on_select_item);
            directory_path = Environment.get_home_dir()+"/.directory_for_txtreader_app";
   GLib.File file = GLib.File.new_for_path(directory_path);
   if(!file.query_exists()){
     try{
        file.make_directory();
     }catch(Error e){
        stderr.printf ("Error: %s\n", e.message);
     }
		}
		GLib.File file1 = GLib.File.new_for_path(directory_path+"/paths");
   if(!file1.query_exists()){
     try{
        file1.make_directory();
     }catch(Error e){
        stderr.printf ("Error: %s\n", e.message);
     }
		}
		GLib.File file2 = GLib.File.new_for_path(directory_path+"/positions");
   if(!file2.query_exists()){
     try{
        file2.make_directory();
     }catch(Error e){
        stderr.printf ("Error: %s\n", e.message);
     }
		}
		show_books();
	}

    private void on_add_clicked () {
        var file_chooser = new FileChooserDialog ("Add a book", this,
                                      FileChooserAction.OPEN,
                                      "_Cancel", ResponseType.CANCEL,
                                      "_Open", ResponseType.ACCEPT);
        if (file_chooser.run () == ResponseType.ACCEPT) {
            string path_to_file = file_chooser.get_filename();
            GLib.File add_file = GLib.File.new_for_path(path_to_file);
        try {
            FileUtils.set_contents (directory_path+"/paths/"+add_file.get_basename(), path_to_file);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
        }
        file_chooser.destroy ();
        show_books();
    }
    private void on_read_clicked(){
       var selection = tree_view.get_selection();
           selection.set_mode(SelectionMode.SINGLE);
           TreeModel model;
           TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
               alert("Choose a book");
               return;
           }
        string path_to_book;
            try {
                FileUtils.get_contents (directory_path+"/paths/"+item, out path_to_book);
            } catch (Error e) {
               stderr.printf ("Error: %s\n", e.message);
            }
            current_file = GLib.File.new_for_path(path_to_book);
            if(!current_file.query_exists()){
                alert("Book not found");
                return;
            }
            string text;
            try {
                FileUtils.get_contents (path_to_book, out text);
            } catch (Error e) {
               stderr.printf ("Error: %s\n", e.message);
            }
            stack.visible_child = read_page;
            set_buttons_on_read_page();
            text_view.buffer.text = text;
            GLib.File f = GLib.File.new_for_path(directory_path+"/positions/"+current_file.get_basename());
            if(f.query_exists()){
            string pos;
            try {
                FileUtils.get_contents (f.get_path(), out pos);
            } catch (Error e) {
               stderr.printf ("Error: %s\n", e.message);
            }
             var dialog_show_position = new Gtk.MessageDialog(this, Gtk.DialogFlags.MODAL,Gtk.MessageType.QUESTION, Gtk.ButtonsType.OK_CANCEL, "Restore the reading position?");
         dialog_show_position.set_title("Question");
         Gtk.ResponseType result = (ResponseType)dialog_show_position.run ();
         dialog_show_position.destroy();
         if(result==Gtk.ResponseType.OK){
            Adjustment adj = read_page.get_vadjustment();
            adj.set_value(int.parse(pos));
            read_page.set_vadjustment(adj);
          }
        }
    }
    private void on_delete_clicked(){
      var selection = tree_view.get_selection();
           selection.set_mode(SelectionMode.SINGLE);
           TreeModel model;
           TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
               alert("Choose a book");
               return;
           }
         var dialog_delete_file = new Gtk.MessageDialog(this, Gtk.DialogFlags.MODAL,Gtk.MessageType.QUESTION, Gtk.ButtonsType.OK_CANCEL, "Delete book "+item+" ?\nThe book will be completely deleted from the device.");
         dialog_delete_file.set_title("Question");
         Gtk.ResponseType result = (ResponseType)dialog_delete_file.run ();
         dialog_delete_file.destroy();
         if(result==Gtk.ResponseType.OK){
         FileUtils.remove (directory_path+"/positions/"+item);
         GLib.File file = GLib.File.new_for_path(directory_path+"/paths/"+item);
         string path;
          try {
            FileUtils.get_contents (file.get_path(), out path);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
        FileUtils.remove (file.get_path());
        FileUtils.remove (path);
         if(file.query_exists()){
            alert("Delete failed");
         }else{
             show_books();
         }
      }
   }
    private void on_back_clicked(){
        stack.visible_child = list_page;
        set_buttons_on_list_page();
        try {
            FileUtils.set_contents (directory_path+"/positions/"+current_file.get_basename(), read_page.vadjustment.value.to_string());
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }
    private void on_select_item(){
           var selection = tree_view.get_selection();
           selection.set_mode(SelectionMode.SINGLE);
           TreeModel model;
           TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
               return;
           }
           TreePath path = model.get_path(iter);
           var index = int.parse(path.to_string());
           if (index >= 0) {
               item = list.nth_data(index);
           }
       }
    private void show_books () {
           list_store.clear();
           list = new GLib.List<string> ();
            try {
            Dir dir = Dir.open (directory_path+"/paths", 0);
            string? name = null;
            while ((name = dir.read_name ()) != null) {
                list.append(name);
            }
        } catch (FileError err) {
            stderr.printf (err.message);
        }
         TreeIter iter;
           foreach (string item in list) {
               list_store.append(out iter);
               list_store.set(iter, Columns.TEXT, item);
           }
       }
    private void set_widget_visible (Gtk.Widget widget, bool visible) {
         widget.no_show_all = !visible;
         widget.visible = visible;
  }
  private void set_buttons_on_list_page(){
      set_widget_visible(back_button,false);
      set_widget_visible(add_button,true);
      set_widget_visible(delete_button,true);
      set_widget_visible(read_button,true);
  }
  private void set_buttons_on_read_page(){
      set_widget_visible(back_button,true);
      set_widget_visible(add_button,false);
      set_widget_visible(delete_button,false);
      set_widget_visible(read_button,false);
  }
   private enum Columns {
           TEXT, N_COLUMNS
       }
     private void alert (string str){
          var dialog_alert = new Gtk.MessageDialog(this, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, str);
          dialog_alert.set_title("Message");
          dialog_alert.run();
          dialog_alert.destroy();
       }
	}
}
