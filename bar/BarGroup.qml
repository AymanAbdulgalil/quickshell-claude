import QtQuick
import ".."

// Icons in a line along the bar: across on a horizontal bar, down on a vertical one.
Grid {
    property int gap: 0

    // Exactly the items it has: spare columns would add a trailing gap to its width.
    columns: Theme.layout.barVertical ? 1 : Math.max(1, visibleChildren.length)
    columnSpacing: gap
    rowSpacing: gap
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
}
