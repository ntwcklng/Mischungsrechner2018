//
//  MischungsrechnerView.swift
//  Mischungsrechner
//
//  Created by Marvin Mieth on 05.03.23.
//  Copyright © 2023 Marvin Mieth. All rights reserved.
//

import SwiftUI

struct MischungsrechnerView: View {
    var testVar = "lol"
    @State private var showDetails = false
    var body: some View {
        
        ZStack {
            Color(UIColor.systemBackground)
            VStack {
                Text(testVar).padding(6).font(.largeTitle)
                Button("huhu") {
                    showDetails.toggle()
                }
                if showDetails {
                    Text("SHOW DETAILS")
                }
                HStack {
                    Text("vstack view").padding(12)
                }.background(Color(UIColor.systemRed))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
    }
}

struct MischungsrechnerView_Previews: PreviewProvider {
    static var previews: some View {
        MischungsrechnerView()
    }
}
