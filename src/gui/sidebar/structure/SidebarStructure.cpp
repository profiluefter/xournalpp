#include "SidebarStructure.h"

#include <i18n.h>


SidebarStructure::SidebarStructure(Control* control, SidebarToolbar* toolbar):
        AbstractSidebarPage(control, toolbar), iconNameHelper(control->getSettings()) {
    this->treeViewStructure = gtk_tree_view_new();
    g_object_ref(this->treeViewStructure);

    this->scrollStructure = gtk_scrolled_window_new(nullptr, nullptr);
    g_object_ref(this->scrollStructure);

    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scrollStructure), GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
    gtk_scrolled_window_set_shadow_type(GTK_SCROLLED_WINDOW(scrollStructure), GTK_SHADOW_IN);

    GtkTreeSelection* selection = gtk_tree_view_get_selection(GTK_TREE_VIEW(treeViewStructure));
    gtk_tree_selection_set_mode(selection, GTK_SELECTION_SINGLE);
    gtk_tree_view_set_headers_visible(GTK_TREE_VIEW(treeViewStructure), false);
    gtk_container_add(GTK_CONTAINER(scrollStructure), treeViewStructure);

    GtkTreeViewColumn* column = gtk_tree_view_column_new();
    gtk_tree_view_column_set_expand(GTK_TREE_VIEW_COLUMN(column), true);
    gtk_tree_view_append_column(GTK_TREE_VIEW(treeViewStructure), column);

    auto* renderer = static_cast<GtkCellRenderer*>(
            g_object_new(GTK_TYPE_CELL_RENDERER_TEXT, "ellipsize", PANGO_ELLIPSIZE_END, nullptr));
    gtk_tree_view_column_pack_start(GTK_TREE_VIEW_COLUMN(column), renderer, true);
    gtk_tree_view_column_set_attributes(GTK_TREE_VIEW_COLUMN(column), renderer, "text", 0, nullptr);

    auto* model = reinterpret_cast<GtkTreeModel*>(gtk_tree_store_new(
            3, G_TYPE_STRING /* file name */, G_TYPE_BOOLEAN /* is file */, G_TYPE_STRING /* absolute path */));

    GtkTreeIter rootNode = {0};
    const fs::path& rootPath = control->getSettings()->getStructureRootFolder();
    gtk_tree_store_insert_with_values(GTK_TREE_STORE(model), &rootNode, nullptr, -1, 0, rootPath.filename().c_str(), 1,
                                      false, 2, absolute(rootPath).c_str(), -1);

    // TODO(profiluefter): Maybe watch folder for changes
    populateTree(model, &rootNode, rootPath);

    auto* sortedModel = reinterpret_cast<GtkTreeModel*>(gtk_tree_model_sort_new_with_model(model));
    gtk_tree_sortable_set_sort_column_id(GTK_TREE_SORTABLE(sortedModel), 0, GTK_SORT_ASCENDING);
    gtk_tree_view_set_model(GTK_TREE_VIEW(this->treeViewStructure), sortedModel);

    unsigned long selectHandler =
            g_signal_connect(treeViewStructure, "cursor-changed", G_CALLBACK(treeNodeSelected), this);
    g_assert(selectHandler != 0);

    gtk_widget_show(this->treeViewStructure);
}

SidebarStructure::~SidebarStructure() {
    g_object_unref(this->treeViewStructure);
    g_object_unref(this->scrollStructure);
}

void SidebarStructure::enableSidebar() { toolbar->setHidden(true); }

void SidebarStructure::disableSidebar() {
    // Nothing to do at the moment
}

std::string SidebarStructure::getName() { return _("Structure"); }

std::string SidebarStructure::getIconName() {
    return this->iconNameHelper.iconName("sidebar-page-preview");  // TODO(profiluefter): Customize icon
}

bool SidebarStructure::hasData() { return true; }

GtkWidget* SidebarStructure::getWidget() { return this->scrollStructure; }

bool SidebarStructure::treeNodeSelected(GtkWidget* treeView, SidebarStructure* sidebar) {
    gtk_widget_grab_focus(GTK_WIDGET(treeView));

    GtkTreeSelection* selection = gtk_tree_view_get_selection(GTK_TREE_VIEW(treeView));

    if (!selection)
        return false;

    GtkTreeModel* model = nullptr;
    GtkTreeIter iter = {0};

    if (!gtk_tree_selection_get_selected(selection, &model, &iter))
        return false;

    bool isFile;
    char* absolutePath;

    gtk_tree_model_get(model, &iter, 1, &isFile, 2, &absolutePath, -1);

    if (!isFile)
        return true;

    // TODO(profiluefter): Add option to automatically save when changed
    sidebar->control->openFile(fs::path(absolutePath));

    return true;
}

void SidebarStructure::populateTree(GtkTreeModel* model, GtkTreeIter* parent, const fs::path& path) {
    for (const auto& file: fs::directory_iterator(path)) {
        GtkTreeIter fileNode = {0};
        gtk_tree_store_insert_with_values(GTK_TREE_STORE(model), &fileNode, parent, -1, 0,
                                          file.path().filename().c_str(), 1, file.is_regular_file(), 2,
                                          absolute(file.path()).c_str(), -1);
        // TODO(profiluefter): Prevent infinite recursion when symlinks are looped
        if (file.is_directory() || file.is_symlink())
            populateTree(model, &fileNode, file.path());
    }
}
