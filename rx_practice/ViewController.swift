//
//  ViewController.swift
//  rx_practice
//
//  Created by TakkuMattsu on 2021/10/27.
//

import Cocoa
import RxSwift
import RxCocoa

func getEmployee(token: String) -> Single<[Employee]> {
    return .just([.init(name: "takkumattsu", age: 37),
                  .init(name: "mironal", age: 17),
                  .init(name: "ryohey", age: 17),
                  .init(name: "yanac", age: 17),
                  .init(name: "numa08", age: 7)])
}

func getLoginInfo() -> Single<LoginInfo> {
    .just(.init(token: "test"))
}

// MARK: - Entity

struct LoginInfo {
    let token: String
}

struct Employee {
    let name: String
    let age: Int
}

extension Employee {
    func toRow() -> EmployeeRow {
        .init(displayName: name + "様", dispalyAge: "\(age)ちゃい")
    }
}

struct EmployeeRow {
    let displayName: String
    let dispalyAge: String
}

protocol ViewModelInputs: AnyObject {
    var loadEmployee: PublishRelay<()> { get }
}

protocol ViewModelOutputs: AnyObject {
    var rows: Driver<[EmployeeRow]> { get }
}

protocol ViewModelType: AnyObject {
    var inputs: ViewModelInputs { get }
    var outputs: ViewModelOutputs { get }
}

// MARK: - ViewModel

class ViewModel: ViewModelType, ViewModelInputs, ViewModelOutputs{
    var inputs: ViewModelInputs { self }
    var outputs: ViewModelOutputs { self }
    var loadEmployee = PublishRelay<Void>()
    let rows: Driver<[EmployeeRow]>
    init() {
        // 画面が表示されたログイン情報を使って
        // APIから社員情報を取得
        // ソートして
        // 表示用の Entity に変換して
        // UIへのアウトプットへ
//        rows = Observable.combineLatest(loadEmployee, getLoginInfo().asObservable())
//            .flatMap { getEmployee(token: $1.token) }
//            .map{
//                let sorted = $0.sorted { $0.age < $1.age }
//                let rows = sorted.map { $0.toRow() }
//                return rows
//            }
//            .asDriver(onErrorDriveWith: .empty())
        rows = loadEmployee
                .withLatestFrom(getLoginInfo().asObservable())
                .flatMap { getEmployee(token: $0.token) }
                .map { $0.sorted { $0.age < $1.age } }
                .map { $0.map { $0.toRow() } }
                .asDriver(onErrorDriveWith: .empty())
        // 注意
        // getLoginInfo()を呼ぶのは `withLatestFrom` で キャッシュされている情報を取得するか、最新のログイン情報を取るかで `flatMap` にするか変わってきます
        // ソートとEmployeeRowの変換の二回、map処理を書いているが計算量が増えるので一つにまとめる方がいい場合もある
    }
}

// MARK: - ViewController

class ViewController: NSViewController {
    
    private let disposedBag = DisposeBag()
    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let viewModel: ViewModelType = ViewModel()
        bind(to: viewModel)
        viewModel.inputs.loadEmployee.accept(())
    }
    
    func bind(to viewModel: ViewModelType) {
        viewModel.outputs.rows
            .drive(onNext: { print($0) })
            .disposed(by: disposedBag)
    }
}
