/*
 * Xournal++
 *
 * Sidebar to display a configured folder as a tree
 *
 * @author Xournal++ Team
 * https://github.com/xournalpp/xournalpp
 *
 * @license GNU GPLv2 or later
 */

#pragma once


#include <string>

#include <control/Control.h>
#include <gui/sidebar/previews/base/SidebarPreviewBase.h>
#include <gui/sidebar/previews/base/SidebarToolbar.h>


class SidebarStructure: public AbstractSidebarPage {
public:
    SidebarStructure(Control* control, SidebarToolbar* toolbar);
    virtual ~SidebarStructure();

public:
    virtual void enableSidebar();
    virtual void disableSidebar();

    /**
     * @overwrite
     */
    virtual std::string getName();

    /**
     * @overwrite
     */
    virtual std::string getIconName();

    /**
     * @overwrite
     */
    virtual bool hasData();

    /**
     * @overwrite
     */
    virtual GtkWidget* getWidget();

private:
    static bool treeNodeSelected(GtkWidget* treeView, SidebarStructure* sidebar);

    void populateTree(GtkTreeModel* model, GtkTreeIter* parent, const fs::path& path);

private:
    GtkWidget* treeViewStructure = nullptr;
    GtkWidget* scrollStructure = nullptr;

    IconNameHelper iconNameHelper;
};
