//
//  ImageView.swift
//  Snap2Spoon
//
//  Created by Cory DeWitt on 11/2/24.
//

import SwiftUI
import Foundation

struct ImageView: View {
    let image: UIImage
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
            
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Scanned Receipt")
    }
}
