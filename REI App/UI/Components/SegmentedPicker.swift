import SwiftUI

struct SegmentedPicker: View {
    var items: [String]
    @Binding var selectedIndex: Int
    
    var body: some View {
        HStack {
            ForEach(0..<items.count, id: \.self) { index in
                Button(action: {
                    selectedIndex = index
                }) {
                    Text(items[index])
                        .fontWeight(selectedIndex == index ? .bold : .regular)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            selectedIndex == index ?
                            AppColors.primary : Color.clear
                        )
                        .cornerRadius(8)
                        .foregroundColor(selectedIndex == index ? .white : .primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SegmentedPicker_Previews: PreviewProvider {
    static var previews: some View {
        SegmentedPicker(items: ["First", "Second", "Third"], selectedIndex: .constant(1))
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 