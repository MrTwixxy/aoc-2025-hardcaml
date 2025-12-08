open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = {
    clock : 'a;
    reset : 'a;
    part : 'a;
    positive : 'a;
    value : 'a; [@bits 16]
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { counter : 'a; [@bits 16] result : 'a [@bits 16] }
  [@@deriving sexp_of, hardcaml]
end

(* 
  Helper function to divide the given number by 100 using division by constants
  Returns both integer division and the modulo
  Dividing by 100 is the same as multiplying by 0.01
  The magic number here is 671089/(2^26), which is very close to 0.01
*)
let divide x =
  let multiplier = Signal.of_int ~width:42 671089 in
  let extended = Signal.uresize x 42 in

  (* Multiply by 671089 *)
  let product = extended *: multiplier in

  (* Bitshift to divide by 2^26 *)
  let q = Signal.srl product 26 in

  (* Division result *)
  let q16 = Signal.select q 15 0 in

  (* Calculate remainder *)
  let r = x -: Signal.uresize (q16 *: Signal.of_int ~width:16 100) 16 in

  (q16, r)

let create (i : _ I.t) =
  let spec = Reg_spec.create ~clock:i.clock () in

  let zero = Signal.of_int ~width:16 0 in
  let one = Signal.of_int ~width:16 1 in

  (* Helper Function to calculate new counter value *)
  let new_counter prev =
    (* Input value *)
    let v = uresize i.value 16 in

    (* Take the remainder of division by 100 *)
    let _, r = divide v in

    (* New position if direction would be left *)
    (* 100 is added to prevent the value from becoming negative *)
    let down = prev +: Signal.of_int ~width:16 100 -: r in

    (* New position if direction would be up *)
    let up = prev +: r in

    (* Prepare and reduce next signal *)
    let next = mux i.positive [ down; up ] in
    let _, reduced = divide next in

    (* Either reset signal or set next signal *)
    mux i.reset [ reduced; Signal.of_int ~width:16 50 ]
  in

  (* 
    Main Position Counter
    The newest value and last value of counter are both used to calculate the result,
    therefore the calculation of the new value has its own function
  *)
  let counter = reg_fb spec ~width:16 ~f:(fun prev -> new_counter prev) in

  (* Result Counter *)
  let result =
    reg_fb spec ~width:16 ~f:(fun prev ->
        (* Calculate New Counter (Also referred to as New Position) *)
        let new_pos = new_counter counter in

        (* Part 1 Logic *)

        (* Check if current position is divisible by 100 *)
        let _, r = divide new_pos in
        let part1 = mux (r ==: zero) [ prev; prev +: one ] in

        (* Part 2 Logic *)
        let v = uresize i.value 16 in

        (* Count full circles and calculate new position *)
        let a, _ = divide v in

        (* Ways of crossing 0 without going a full circle *)
        (* Crossing while going left *)
        let b =
          mux
            (counter <>: zero &: (new_pos <>: zero) &: ~:(i.positive)
           &: (new_pos >: counter))
            [ zero; one ]
        in
        (* Crossing while going right *)
        let c =
          mux
            (counter <>: zero &: (new_pos <>: zero) &: i.positive
           &: (new_pos <: counter))
            [ zero; one ]
        in
        (* Ending on a 0 *)
        let d = mux (counter <>: zero &: (new_pos ==: zero)) [ zero; one ] in

        (* Total amount of crossings *)
        let part2 = prev +: a +: b +: c +: d in

        (* Prepare next signal depending on requested part *)
        let next = mux i.part [ part1; part2 ] in

        (* Either reset signal or set next signal *)
        mux i.reset [ next; zero ])
  in

  (* Assign values to outputs *)
  { O.counter; O.result }
