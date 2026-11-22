import QtQuick
import "."

Item {
    id: root
    // Referencing WeatherService ensures its background singleton is instantiated and running
    readonly property var _svc: WeatherService
}
