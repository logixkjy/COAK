//
//  SplashView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color(.blue01)
                    .edgesIgnoringSafeArea(.all)
                
                Image("launch03")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
