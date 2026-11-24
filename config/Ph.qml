pragma Singleton

import Quickshell
import "Phosphor.js" as Map

// Phosphor icon lookup by name.
Singleton {
    function get(name: string): string { return Map.get(name); }
    function has(name: string): bool { return Map.map[name] !== undefined; }
}
