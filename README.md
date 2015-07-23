# CoreModel

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Swift ORM wrapper. 

Wraps Core Data (Darwin only) and other ORMs into a familiar interface. Used for cross-platform Swift development. 
Built with Swift 2.0 and targeting OS X, iOS and, Linux.

## Usage & Goals

- Create immutable structs
- Entity Type contains model description
- Model is just an array of types
- Struct compatibility
- Entity can be protocol for Client / Server code sharing, for example:
	- Entity properties are defined in protocol: (CoreProjectModel.UserType: Entity) 
	- Client defines Struct or class with no initialization side effects (CoreProjectClient.User) 
	- Server defines structs with initialization side effects
	- Bonus: Setting data from JSON can be protocol extension
