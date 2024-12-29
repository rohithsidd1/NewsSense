import SwiftUI

struct NYTResponse: Codable {
    let results: [NYTArticle]
}

struct NYTArticle: Codable {
    let title: String
    let abstract: String
    let url: String
    let multimedia: [NYTMultimedia]?
}

struct NYTMultimedia: Codable {
    let url: String
    let format: String
}

struct NewsArticle: Identifiable {
    let id = UUID() // Unique identifier for each article
    let title: String
    let description: String?
    let urlToImage: String?
    let url: String?
}

class NewsViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let apiKey = "4LBh9aAZKNtYMQTxWTkPDTUhBLdPyN0B" // Replace with your NYT API key
    private let baseUrl = "https://api.nytimes.com/svc/topstories/v2"
    private var currentCategoryIndex = 0
    
    let categories = ["world", "business", "technology", "science", "health", "sports", "arts"]
    
    func fetchNews(for category: String) {
        guard !isLoading else { return }
        
        guard let url = URL(string: "\(baseUrl)/\(category).json?api-key=\(apiKey)") else {
            errorMessage = "Invalid URL."
            return
        }
        
        isLoading = true
        errorMessage = nil
        articles = [] // Clear articles for the new category
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received."
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(NYTResponse.self, from: data)
                    self?.articles = response.results.map {
                        NewsArticle(
                            title: $0.title,
                            description: $0.abstract,
                            urlToImage: $0.multimedia?.first?.url,
                            url: $0.url
                        )
                    }
                } catch {
                    self?.errorMessage = "Failed to decode JSON: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NewsViewModel()
    @State private var selectedIndex = 0

    private let cardSpacing: CGFloat = 30.0
    private let cardScale: CGFloat = 0.85
    @State private var selectedCategory = "world" // Default category


    var body: some View {
        ZStack {
            Color(red: 222 / 255, green: 227 / 255, blue: 221 / 255)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) { // Ensure no gaps between elements
                ZStack {
                    Rectangle()
                        .fill(Color(red: 242 / 255, green: 247 / 255, blue: 241 / 255))
                        .frame(height: 108) // Adjust height as needed
                    HStack {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 32) // Adjust size as needed
                            .padding(.leading)
                        Spacer()
                        
                        
                        Text("Live news")
                            .font(Font.custom("Lexend-Light", size: 14)) // Use your custom font
                            .foregroundColor(Color(red: 28 / 255, green: 79 / 255, blue: 74 / 255)) // Dark green text color
                            .padding(.horizontal, 12) // Padding for horizontal space
                            .padding(.vertical, 8) // Padding for vertical space
                            .background(
                                Color(red: 222 / 255, green: 227 / 255, blue: 221 / 255)
                            )
                            .cornerRadius(12) // Rounded corners
                            .padding(.trailing, 8)


                        Image("Menu")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 42) // Adjust size as needed
                            .padding(.trailing)

                    }
                    .padding(.top, 54)

                }
                
                HStack{
                    Spacer()
                    // "Design" image just below the ZStack
                    Image("Design")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                }

                Spacer() // Push the rest of the content below the white bar
                VStack(spacing: 8){
                    HStack{
                        Text("News")
                            .font(Font.custom("Lexend-SemiBold", size: 28)) // Use your custom font
                            .foregroundColor(Color(red: 28 / 255, green: 79 / 255, blue: 74 / 255))
                            .padding(.leading)
                        
                        Spacer()
                    }
                    
                    Menu {
                        // Add a button for each category
                        ForEach(viewModel.categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                                viewModel.fetchNews(for: category)
                            }) {
                                Text(category.capitalized)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Get News by :")
                                .font(Font.custom("Lexend-Regular", size: 16)) // Use your custom font
                                .foregroundColor(Color.white.opacity(0.8)) // Adjust opacity for the lightened text color
                                .padding(.leading, 16)
                            
                            Text(selectedCategory.capitalized)
                                .font(Font.custom("Lexend-Medium", size: 18)) // Use your custom font
                                .foregroundColor(.white)
                                .padding(.leading, 4)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(Color.white.opacity(0.8)) // Adjust opacity for lighter icon
                                .padding(.trailing, 16)
                        }
                        .frame(height: 50) // Adjust height for the component
                        .background(Color(red: 28 / 255, green: 79 / 255, blue: 74 / 255)) // Dark green background
                        .cornerRadius(12) // Rounded corners
                        .padding(.horizontal, 16) // Optional padding for screen edges
                        .padding(.bottom)
                    }
                }

                if viewModel.isLoading && viewModel.articles.isEmpty {
                    VStack {
                        ForEach(0..<1, id: \.self) { _ in
                            ShimmerCard()
                        }
                    }
                } else if let errorMessage = viewModel.errorMessage, viewModel.articles.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ZStack {
                        ForEach(viewModel.articles.indices, id: \.self) { index in
                            NewsRowView(article: viewModel.articles[index])
                                .zIndex(zIndex(for: index))
                                .scaleEffect(scale(for: index))
                                .offset(x: offset(for: index), y: yOffset(for: index))
                                .rotationEffect(rotation(for: index))
                                .opacity(opacity(for: index))
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3),
                                    value: selectedIndex
                                )
                                .gesture(
                                    DragGesture()
                                        .onEnded { gesture in
                                            if gesture.translation.width < -50, selectedIndex < viewModel.articles.count - 1 {
                                                selectedIndex += 1
                                            } else if gesture.translation.width > 50, selectedIndex > 0 {
                                                selectedIndex -= 1
                                            }
                                        }
                                )
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchNews(for: selectedCategory)
            }
        }
        .edgesIgnoringSafeArea(.top)
    }

    // MARK: - Card Positioning Helpers

    private func zIndex(for index: Int) -> Double {
        return index == selectedIndex ? 1 : 0
    }

    private func scale(for index: Int) -> CGFloat {
        return index == selectedIndex ? 1.0 : cardScale
    }

    private func offset(for index: Int) -> CGFloat {
        if index < selectedIndex {
            return -200 + CGFloat(index - selectedIndex) * cardSpacing
        } else if index > selectedIndex {
            return 200 + CGFloat(index - selectedIndex) * cardSpacing
        } else {
            return 0
        }
    }

    private func yOffset(for index: Int) -> CGFloat {
        return index == selectedIndex ? 0 : 20
    }

    private func rotation(for index: Int) -> Angle {
        if index < selectedIndex {
            return Angle(degrees: -5)
        } else if index > selectedIndex {
            return Angle(degrees: 5)
        } else {
            return Angle(degrees: 0)
        }
    }

    private func opacity(for index: Int) -> Double {
        return index == selectedIndex ? 1.0 : 0.6
    }
}

import SwiftUI

struct NewsRowView: View {
    let article: NewsArticle

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(Font.custom("Lexend-SemiBold", size: 22)) // Use your custom font
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(article.description ?? "No description available.")
                        .font(Font.custom("Lexend-Light", size: 14)) // Use your custom font
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
                
                VStack(spacing: 16){
                    HStack{
                        // "Read Full Article" button
                        if let articleUrl = article.url, let url = URL(string: articleUrl) {
                            Link(destination: url) {
                                HStack{
                                    HStack(spacing: 8) { // Spacing between the circle and text
                                        // Circular background with the arrow
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange)
                                                .frame(width: 36, height: 36) // Circle size
                                            Image(systemName: "arrow.right")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .bold)) // Arrow size
                                        }
                                        
                                        // Text next to the circle
                                        Text("Read full article")
                                            .font(Font.custom("Lexend-Medium", size: 18)) // Use your custom font
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }

                    // Image of the article
                    if let urlString = article.urlToImage, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFit()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill the entire space
            .background(Color(red: 28 / 255, green: 79 / 255, blue: 74 / 255)) // Updated background color
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
        }
        .frame(height: UIScreen.main.bounds.height * 0.62) // Force each row to take up the full screen height
    }
}


import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1), Color.gray.opacity(0.3)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 200)
                .rotationEffect(.degrees(0))
                .offset(x: phase * 350 - 150) // Animate the gradient across
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}


struct ShimmerCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 432)
                .cornerRadius(8)
                .shimmer() // Apply shimmer effect
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
                .cornerRadius(4)
                .padding(.top, 8)
                .shimmer()
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 16)
                .cornerRadius(4)
                .padding(.top, 4)
                .shimmer()
        }
        .padding()
    }
}
