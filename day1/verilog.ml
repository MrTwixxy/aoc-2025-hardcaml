open Hardcaml
open Day1
module Day1Circuit = Circuit.With_interface (Datapath.I) (Datapath.O)

let circuit = Day1Circuit.create_exn Datapath.create ~name:"datapath"

(* Convert and print Verilog circuit *)
let () = Rtl.print Verilog circuit
