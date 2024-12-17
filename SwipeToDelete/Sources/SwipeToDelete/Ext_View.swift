import SwiftUI

extension View {
    
    /// A modifier that allows for any View to have swipe to delete functionality
    /// - Parameter completion: Completion that is fired after delete action is called
    /// - Returns: Modified View
    public func swipeToDelete(completion: @escaping () -> Void) -> some View {
        self.modifier(SwipeToDeleteModifier(deleteCompletion: completion))
    }
    
}
