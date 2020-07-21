import Foundation

/// A protocol that provides ability of formatting `Date` object into a readable string. `DateFormatter` is the example who fulfills this responsibility.
///
/// Discussion: Adding this protocol is mean to extract the ability of formatting a `Date` object out of `DateFormatter` and shadow other abilities that a
/// `DateFormatter`. For example, instead of returning `DateFormatter` from a dateFormatterFactory, returning the shadow - `DateFormatting`
/// which end users to alter the formatter while using.
protocol DateFormatting {

    func string(from date: Date) -> String
}

// `DateFormatter` is already conforming to `DateFormatting` protocol
extension DateFormatter: DateFormatting {}