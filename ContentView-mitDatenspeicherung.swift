import SwiftUI

// MARK: - Model
struct Question: Identifiable {
    let id = UUID()
    let text: String
    let options: [String]
}

struct QuestionStatistics: Codable {
    var counts: [String: Int]
    
    init(options: [String]) {
        counts = Dictionary(uniqueKeysWithValues: options.map { ($0, 0) })
    }
    
    mutating func recordAnswer(_ answer: String) {
        counts[answer, default: 0] += 1
    }
}

// MARK: - ViewModel
class SurveyViewModel: ObservableObject {
    
    
    
        init() {
            currentAnswers = Array(repeating: nil, count: questions.count)
            statistics = questions.map { QuestionStatistics(options: $0.options) }
            
            // Versuchen, gespeicherte Umfrageergebnisse zu laden
            loadSavedResults()
        }

    
    @Published var questions: [Question] = [
        Question(text: "Geschlecht", options: ["männlich", "weiblich", "divers", "keine Angabe"]),
        Question(text: "Altersgruppe", options: ["u18", "18-39", "30-39", "40-49", "50-59", "60-69", "70-79", "ü80","keine Angabe"]),
        Question(text: "Welchen Kanzlerkandidat würden Sie bevorzugen?", options: ["Friedrich Merz (CDU)", "Olaf Scholz (SPD)", "Robert Habeck (Bündnis 90 / Die Grünen)", "Christian Lindner (FDP)", "Alice Weidel (AfD)", "Sahra Wagenknecht (BSW)", "Jan van Aken (Die Linke)" ,"Keinen der aufgeführten"]),
        Question(text: "Fühlen Sie sich von den aktuellen Parteien repräsentiert?", options: ["trifft zu", "trifft eher zu", "trifft eher nicht zu", "trifft nicht zu"]),
        Question(text: "Wie zufrieden sind Sie mit der Regierungsarbeit der Ampel?", options: ["zufrieden", "eher zufrieden", "eher unzufrieden", "unzufrieden"]),
        Question(text: "Ist die Demokratie in Deutschland gefährdet?", options: ["Nein", "Ja, durch Rechtsextremismus", "Ja, durch Linksextremismus", "Ja, durch Links- und Rechtsextremismus", "Ja"]),
        Question(text: "Fühlen Sie sich finanziell sicher?", options: ["ja", "eher ja", "eher nein", "nein"]),
        Question(text: "Welches Thema ist für Sie am wichtigsten?", options: ["Freiheit", "Sicherheit", "Migration", "Außenpolitik (z.B. Kriege)", "stabile Wirtschaftslage", "Schutz unserer Demokratie", "Keines der aufgeführten Themen"]),
        Question(text: "Engagieren Sie sich politisch?", options: ["Ja, in einer Partei", "Ja, unabhängig von Parteien", "Nein, aber Politik interessiert mich", "Nein, denn Politik interessiert mich nicht"]),
        Question(text: "Bei der Bundestagswahl wählen wir...", options: ["... einen Wahlkreiskandidaten und eine Partei.", "...nur eine Partei.", "... den Bundeskanzler.", "... nur einen Wahlkreiskandidaten."]),
        Question(text: "error-1", options: ["error-2", "error-3", "error-4", "error-5"])
    ]
    
    @Published var statistics: [QuestionStatistics] = []
    @Published var currentAnswers: [String?] = []
    @Published var currentIndex: Int = 0
    @Published var isSurveying: Bool = false
    @Published var totalParticipants: Int = 0
    
    
    
    var isLastQuestion: Bool {
        return currentIndex == questions.count - 1
    }
    
    func submitAnswer(_ answer: String) {
        currentAnswers[currentIndex] = answer
        if !isLastQuestion {
            currentIndex += 1
        }
    }
    
    func finishSurvey() {
        // Ergebnisse speichern
        for (index, answer) in currentAnswers.enumerated() {
            if let answer = answer {
                statistics[index].recordAnswer(answer)
            }
        }
        
        // Teilnehmeranzahl erhöhen
        totalParticipants += 1
        
        // Ergebnisse in UserDefaults speichern
        saveResults()
        
        // Umfrage zurücksetzen
        resetSurvey()
    }
    
    func resetSurvey() {
        currentAnswers = Array(repeating: nil, count: questions.count)
        currentIndex = 0
    }
}

// MARK: - Views
struct ContentView: View {
    @StateObject private var viewModel = SurveyViewModel()
    @State private var showResults = false
    @State private var askNextPerson = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if showResults {
                    OverallResultsView(statistics: viewModel.statistics, totalParticipants: viewModel.totalParticipants, questions: viewModel.questions)
                } else if viewModel.isSurveying {
                    QuestionView(viewModel: viewModel, askNextPerson: $askNextPerson)
                } else {
                    StartSurveyView(viewModel: viewModel, showResults: $showResults)
                }
            }
            .navigationTitle("Umfrage")
            .alert(isPresented: $askNextPerson) {
                Alert(
                    title: Text("Nächste Person?"),
                    message: Text("Möchtest du eine weitere Person befragen oder die Ergebnisse anzeigen?"),
                    primaryButton: .default(Text("Weitere Person"), action: {
                        viewModel.isSurveying = false
                    }),
                    secondaryButton: .default(Text("Ergebnisse anzeigen"), action: {
                        showResults = true
                    })
                )
            }
        }
    }
}

struct StartSurveyView: View {
    @ObservedObject var viewModel: SurveyViewModel
    @Binding var showResults: Bool
    
    var body: some View {
        VStack {
            Text("Neue Umfragerunde")
                .font(.title)
                .padding(.bottom, 20)
            
            Button(action: {
                viewModel.isSurveying = true
            }) {
                Text("Umfrage starten")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: {
                showResults = true
            }) {
                Text("Gesamtergebnisse anzeigen")
                    .padding()
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}

struct QuestionView: View {
    @ObservedObject var viewModel: SurveyViewModel
    @Binding var askNextPerson: Bool
    
    var body: some View {
        VStack {
            Text(viewModel.questions[viewModel.currentIndex].text)
                .font(.title2)
                .padding()
            
            ForEach(viewModel.questions[viewModel.currentIndex].options, id: \.self) { option in
                Button(action: {
                    viewModel.submitAnswer(option)
                    if viewModel.isLastQuestion {
                        viewModel.finishSurvey()
                        askNextPerson = true
                    }
                }) {
                    Text(option)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct OverallResultsView: View {
    let statistics: [QuestionStatistics]
    let totalParticipants: Int
    let questions: [Question]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Gesamtergebnisse")
                    .font(.largeTitle)
                    .padding(.bottom, 20)
                
                Text("Anzahl der Teilnehmer: \(totalParticipants)")
                    .font(.headline)
                    .padding(.bottom, 20)
                
                ForEach(questions.indices, id: \.self) { index in
                    let question = questions[index]
                    let stats = statistics[index]
                    
                    Text("\(index + 1). \(question.text)")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    ForEach(question.options, id: \.self) { option in
                        Text("\(option): \(stats.counts[option, default: 0])")
                            .padding(.bottom, 5)
                    }
                    
                    Divider()
                        .padding(.vertical)
                }
                
                
                
            
            }
            .padding()
        }
    }
}

// MARK: - App Entry Point
struct SurveyApp: View {
    var body: some View {
        ContentView()
    }
}

import Foundation

extension SurveyViewModel {
    
    // Funktion zum Speichern der Umfrageergebnisse in UserDefaults
    func saveResults() {
        let defaults = UserDefaults.standard
        
        // Speichern der Umfrageergebnisse (statistiken und Teilnehmeranzahl)
        let statisticsData = try? JSONEncoder().encode(statistics)
        defaults.set(statisticsData, forKey: "surveyStatistics")
        defaults.set(totalParticipants, forKey: "totalParticipants")
    }
    
    // Funktion zum Laden der Umfrageergebnisse aus UserDefaults
    func loadSavedResults() {
        let defaults = UserDefaults.standard
        
        // Überprüfen, ob gespeicherte Daten vorhanden sind
        if let savedStatisticsData = defaults.data(forKey: "surveyStatistics"),
           let savedStatistics = try? JSONDecoder().decode([QuestionStatistics].self, from: savedStatisticsData) {
            statistics = savedStatistics
        }
        
        // Laden der Teilnehmeranzahl
        totalParticipants = defaults.integer(forKey: "totalParticipants")
    }
}
