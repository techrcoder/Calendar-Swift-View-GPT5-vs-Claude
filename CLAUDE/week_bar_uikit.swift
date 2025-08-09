import UIKit
import SwiftUI

// MARK: - Week Bar UIKit Implementation
class WeekBarViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var viewModel: CalendarViewModel!
    private var onDateSelected: ((Date) -> Void)?
    private var onSwipeDown: (() -> Void)?
    
    // Infinite scrolling parameters
    private let totalSections = 10000
    private let middleSection = 5000
    private var referenceDate: Date!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupGestures()
    }
    
    func configure(viewModel: CalendarViewModel, 
                  onDateSelected: @escaping (Date) -> Void,
                  onSwipeDown: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDateSelected = onDateSelected
        self.onSwipeDown = onSwipeDown
        self.referenceDate = Calendar.current.startOfDay(for: viewModel.selectedDate)
        
        // Scroll to current week
        DispatchQueue.main.async {
            self.scrollToCurrentWeek(animated: false)
        }
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: view.bounds.width / 7, height: 80)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(WeekDayCell.self, forCellWithReuseIdentifier: "WeekDayCell")
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupGestures() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }
    
    @objc private func handleSwipeDown() {
        onSwipeDown?()
    }
    
    private func scrollToCurrentWeek(animated: Bool) {
        let indexPath = IndexPath(item: 0, section: middleSection)
        collectionView.scrollToItem(at: indexPath, at: .left, animated: animated)
    }
    
    func updateSelectedDate(_ date: Date) {
        // Find the section that contains this date
        let calendar = Calendar.current
        let weeksDiff = calendar.dateComponents([.weekOfYear], 
                                              from: referenceDate, 
                                              to: date).weekOfYear ?? 0
        let targetSection = middleSection + weeksDiff
        
        let indexPath = IndexPath(item: 0, section: targetSection)
        collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
    }
}

// MARK: - Collection View Data Source & Delegate
extension WeekBarViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return totalSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7 // Always 7 days in a week
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeekDayCell", for: indexPath) as! WeekDayCell
        
        let calendar = Calendar.current
        let weekOffset = indexPath.section - middleSection
        let dayOffset = indexPath.item
        
        if let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: referenceDate),
           let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
            
            let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)
            let isToday = calendar.isDate(date, inSameDayAs: Date())
            
            cell.configure(with: date, isSelected: isSelected, isToday: isToday)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let calendar = Calendar.current
        let weekOffset = indexPath.section - middleSection
        let dayOffset = indexPath.item
        
        if let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: referenceDate),
           let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
            onDateSelected?(date)
        }
    }
}

// MARK: - Week Day Cell
class WeekDayCell: UICollectionViewCell {
    private let dayLabel = UILabel()
    private let dateLabel = UILabel()
    private let selectionView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        selectionView.backgroundColor = .systemBlue
        selectionView.layer.cornerRadius = 20
        selectionView.isHidden = true
        
        dayLabel.font = .systemFont(ofSize: 12, weight: .medium)
        dayLabel.textAlignment = .center
        dayLabel.textColor = .secondaryLabel
        
        dateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        dateLabel.textAlignment = .center
        dateLabel.textColor = .label
        
        contentView.addSubview(selectionView)
        contentView.addSubview(dayLabel)
        contentView.addSubview(dateLabel)
        
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            selectionView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 10),
            selectionView.widthAnchor.constraint(equalToConstant: 40),
            selectionView.heightAnchor.constraint(equalToConstant: 40),
            
            dayLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            dayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dayLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            dateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 10)
        ])
    }
    
    func configure(with date: Date, isSelected: Bool, isToday: Bool) {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        dayLabel.text = formatter.string(from: date).uppercased()
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        dateLabel.text = dayFormatter.string(from: date)
        
        if isSelected {
            selectionView.isHidden = false
            selectionView.backgroundColor = isToday ? .systemRed : .systemBlue
            dateLabel.textColor = .white
        } else {
            selectionView.isHidden = true
            dateLabel.textColor = isToday ? .systemRed : .label
        }
    }
}

// MARK: - SwiftUI Wrapper for WeekBar
struct WeekBarView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: CalendarViewModel
    let onSwipeDown: () -> Void
    
    func makeUIViewController(context: Context) -> WeekBarViewController {
        let controller = WeekBarViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: WeekBarViewController, context: Context) {
        uiViewController.configure(
            viewModel: viewModel,
            onDateSelected: { date in
                viewModel.selectDate(date)
            },
            onSwipeDown: onSwipeDown
        )
        
        // Update selection when date changes externally
        uiViewController.updateSelectedDate(viewModel.selectedDate)
    }
}