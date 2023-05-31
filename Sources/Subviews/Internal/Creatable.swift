internal struct Creatable<Value, Creator> {
    private var create: (Creator?) -> Value?
    
    var stored: Value? {
        create(nil)
    }
    func resolve(with creator: Creator) -> Value? {
        create(creator)
    }
    
    init(_ value: Value?) {
        self.create = { _ in value }
    }
    
    @_disfavoredOverload
    init(create: ((Creator) -> Value?)?) {
        if let create {
            self.init(create: create)
        } else {
            self.init(nil)
        }
    }
    
    init(create: @escaping (Creator) -> Value?) {
        var __created: Value?
        self.create = { creator in
            guard let creator else {
                return __created
            }
            
            if let __created {
                return __created
            } else {
                let new = create(creator)
                __created = new
                return new
            }
        }
    }
}
