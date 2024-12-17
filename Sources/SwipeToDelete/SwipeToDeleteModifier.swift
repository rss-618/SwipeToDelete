import SwiftUI

/// A more generic swipe to delete modifier
/// Kept this simple on purpose
struct SwipeToDeleteModifier: ViewModifier {
    
    // Constants
    let PEEK_WIDTH: CGFloat = -80
    let PERCENT_75: CGFloat = 0.75
    let ANIMATION_DURATION: CGFloat = 0.3
    let MIN_DRAG: CGFloat = 10
    let DELETE_ICON: String = "trash.fill"
    let DELETE_TEXT: String = "Delete"
    
    // Param
    let deleteCompletion: () -> Void
    
    // State Vars
    @GestureState var isDragging: Bool = false
    @State var offset: CGSize = .zero
    @State var oldOffset: CGSize = .zero
    @State var isPressed: Bool = false
    @State var width: CGFloat = .greatestFiniteMagnitude
    
    // Get Variables
    var isButtonDisabled: Bool {
        offset != .zero
    }
    
    var PEEK_INITIATING_THRESHOLD: CGFloat {
        PEEK_WIDTH / 2
    }
    
    var DELETE_SWIPE_THRESHOLD : CGFloat {
        -(width * PERCENT_75)
    }
    
    var showDeleteButton: Bool {
        (offset.width / PEEK_WIDTH) > PERCENT_75
    }
    
    var deleteButtonWidth: CGFloat {
        min(-offset.width, -PEEK_WIDTH)
    }
    
    @ViewBuilder
    @MainActor
    func body(content: Content) -> some View {
        ZStack {
            HStack {
                Spacer()
                ZStack(alignment: .trailing) {
                    Color.red
                    
                    deleteButton
                }
                .frame(width: -offset.width)
            }
            
            content
                .disabled(isButtonDisabled)
                .offset(offset)
                .simultaneousGesture(drag)
                .gesture(isButtonDisabled ? tap : nil)
        }
        .animation(.smooth(duration: ANIMATION_DURATION), value: offset)
        .background {
            // (RSS) Geometry reader cannot be the direct parent or it will overlap things in a list
            GeometryReader { proxy in
                Rectangle()
                    .opacity(.zero)
                    .onAppear {
                        width = proxy.size.width
                    }
            }
        }
        .onAppear {
            resetOffset()
        }
        .onDisappear {
            resetOffset()
        }
        .onChange(of: isDragging) { value in
            // (RSS) cannot use the onEnded within DragGesture, because it does not get initiated upon cancel
            // which can happen during a scroll view scroll
            if !value {
                swipeEnded()
            }
        }
    }
    
    var deleteIcon: some View {
        VStack {
            Image(systemName: DELETE_ICON)
            Text(DELETE_TEXT)
                .lineLimit(1)
                .font(.caption)
        }
        .foregroundStyle(Color.white)
    }
    
    var deleteButton: some View {
        Button {
            // Simulate full swipe
            offset.width = -width
            swipeEnded()
        } label: {
            HStack(spacing: .zero) {
                if showDeleteButton {
                    deleteIcon
                        .transition(.scale)
                }
            }
            .frame(width: deleteButtonWidth)
        }
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: MIN_DRAG, coordinateSpace: .global)
            .updating($isDragging) { _, isDragging, _ in
                isDragging = true
            }
            .onChanged { value in
                // Keep track of the old offset vs the new translation
                let newPos = oldOffset.width + value.translation.width
                if newPos <= .zero {
                    offset.width = newPos
                }
            }
    }
    
    var tap: some Gesture {
        TapGesture().onEnded {
            resetOffset()
        }
    }
    
    func swipeEnded() {
        DispatchQueue.main.async {
            if offset.width < DELETE_SWIPE_THRESHOLD {
                // Swipe to delete
                offset.width = -width
                // Wait for animation to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + ANIMATION_DURATION) {
                    deleteCompletion()
                    // (RSS) we need this timed just in case an error occurs immediately after removal
                    // .onDisappear does not fire quick enough
                    DispatchQueue.main.asyncAfter(deadline: .now() + ANIMATION_DURATION) {
                        resetOffset()
                    }
                }
                
            } else if offset.width < PEEK_INITIATING_THRESHOLD {
                // Show Widget
                offset.width = PEEK_WIDTH
            } else {
                // Hide Widget
                offset = .zero
            }
            // This is now the old offset
            self.oldOffset = offset
        }
    }
    
    func resetOffset() {
        DispatchQueue.main.async {
            self.offset = .zero
            self.oldOffset = .zero
        }
    }
    
}
