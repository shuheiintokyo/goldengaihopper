import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("showEnglish") var showEnglish = false
    @State private var imageOffset: CGFloat = -UIScreen.main.bounds.height
    @State private var showContent = false
    @State private var slideRight = false
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        // Remove NavigationView and use plain ZStack for full-screen layout
        ZStack {
            // Background image
            Image("LoginBackground")
                .resizable()
                .ignoresSafeArea()
            
            // Animated image
            Image("Kaachan")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200)
                .offset(y: imageOffset)
                .offset(x: slideRight ? UIScreen.main.bounds.width : 0)
            
            // Main content
            VStack(spacing: 20) {
                Text("Golden Peace")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white) // Making text white to be visible on background
                    .padding(.bottom, 50)
                
                Text("言語を選択 / Select Language")
                    .font(.headline)
                    .foregroundColor(.white) // Making text white to be visible on background
                    .padding()
                
                // Japanese button first
                Button(action: {
                    showEnglish = false
                    isLoggedIn = true
                }) {
                    Text("日本語")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // English button second
                Button(action: {
                    showEnglish = true
                    isLoggedIn = true
                }) {
                    Text("English")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 100)
            .opacity(contentOpacity)
        }
        .ignoresSafeArea() // Ensure full screen coverage
        .onAppear {
            // Start the animation sequence
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(3)) {
                imageOffset = 0 // Move to center
            }
            
            // Start fading in content as Kaachan starts sliding right
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.8) {
                withAnimation(.easeIn(duration: 1.5)) {
                    contentOpacity = 1
                }
            }
            
            // Slide Kaachan right
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.8) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    slideRight = true
                }
            }
        }
    }
}
