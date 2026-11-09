import QtQuick
import QtQuick.Layouts
import ".."
import "../notifications"

ColumnLayout {
    spacing: Theme.space.xxs

    PageTitle {
        text: "Notifications"
    }

    NotificationSettings {}
}
