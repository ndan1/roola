//
//  BodyPartCard.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 08/11/25.
//

import SwiftUI

import SwiftUI

struct BodyPartCard: View {
    var bodyParts: String
    var bodyPartsImg: String
    var body: some View {
        GeometryReader { geo in
                VStack() {
                    Text(bodyParts)
                        .foregroundStyle(.black)
                        .padding(.bottom, 4)
                    
                    Image(bodyPartsImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.9)
                        .frame(width: geo.size.width * 0.4)
                }
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: UIScreen.main.bounds.height * 0.28)
    }
}

#Preview {
    VStack{
        HStack{
            BodyPartCard(bodyParts: "Chest", bodyPartsImg: "Torso 9")
            BodyPartCard(bodyParts: "chest", bodyPartsImg: "Torso 9 2")
        }
        HStack{
            BodyPartCard(bodyParts: "Chest", bodyPartsImg: "Torso 9")
            BodyPartCard(bodyParts: "chest", bodyPartsImg: "Torso 9 2")
        }
        
    }
}
