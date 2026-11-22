import QtQuick
import "."

Item {
    id: root
    // Referencing singletons ensures they are active and running in background
    readonly property var _quoteSvc: QuoteService
    readonly property var _greetSvc: GreetingService
}
