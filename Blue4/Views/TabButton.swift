//
//  TabButton.swift
//  Blue4
//
//  Created by Athul Joseph on 27/01/23.
//

import SwiftUI

struct TabButton: View {
    var image: String
    var title: String
    var tab: ViewTab
    @Binding var selectedTab: ViewTab
    
    var body: some View {
        
        Button(action: {withAnimation{selectedTab = tab}}, label: {
            
            VStack(spacing: 8) {
                
                Image(systemName: image)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                
                Text(title)
                    .fontWeight(.semibold)
                    .font(.system(size: 12))
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
            .frame(width: 80)
            .contentShape(Rectangle())
            .background(Color.primary.opacity(selectedTab == tab ? 0.16 : 0))
            .cornerRadius(8)
        })
        .buttonStyle(PlainButtonStyle())
    }
}