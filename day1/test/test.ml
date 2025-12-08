open Hardcaml
open Hardcaml_waveterm
open Day1.Datapath
module Simulator = Cyclesim.With_interface (I) (O)

(* Helper function to count the amount of lines in an input file *)
let count_lines file =
  let ic = open_in file in
  let rec loop acc =
    match input_line ic with
    | _ -> loop (acc + 1)
    | exception End_of_file ->
        close_in ic;
        acc
  in
  loop 0

(* Tests for the line counting function *)
let%expect_test "Linecount A" =
  print_int (count_lines "../tests/a.input");
  [%expect "10"]

let%expect_test "Linecount B" =
  print_int (count_lines "../tests/b.input");
  [%expect "4545"]

let%expect_test "Linecount C" =
  print_int (count_lines "../tests/c.input");
  [%expect "4543"]

(*
  Main test runner 
  Parses and runs a test file
  Please note that the parser is expects
  files to use LF newlines, using CRLF
  files will cause errors
*)
let test_file file part_two =
  let sim = Simulator.create create in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in

  (*
    Start off with a reset signal so the circuit
    doesn't take the initial state of 0 as a step
    ending at zero
  *)
  let () =
    inputs.reset := Bits.vdd;
    inputs.part := Bits.gnd;
    inputs.positive := Bits.gnd;
    inputs.value := Bits.of_int ~width:16 0;
    Cyclesim.cycle sim
  in

  (* Step function which is called on every clock cycle *)
  let step positive value =
    inputs.reset := Bits.gnd;
    inputs.part := if part_two then Bits.vdd else Bits.gnd;
    inputs.positive := if positive then Bits.vdd else Bits.gnd;
    inputs.value := Bits.of_int ~width:16 value;
    Cyclesim.cycle sim
  in

  (* Actual file parsing *)
  let ic = open_in file in
  let () =
    for _ = 1 to count_lines file do
      let line = input_line ic in
      let positive = String.get line 0 = 'R' in
      let value = int_of_string (String.sub line 1 (String.length line - 1)) in
      step positive value
    done
  in

  (* Close file after testing *)
  close_in ic;

  (* Return test results *)
  (waves, outputs.result)

(* Main Tests *)
(* Part 1 Tests *)
let%expect_test "Part 1 - Test A" =
  let _, result = test_file "../tests/a.input" false in
  print_int (Bits.to_int !result);
  [%expect "3"]

let%expect_test "Part 1 - Test B" =
  let _, result = test_file "../tests/b.input" false in
  print_int (Bits.to_int !result);
  [%expect "1132"]

let%expect_test "Part 1 - Test C" =
  let _, result = test_file "../tests/c.input" false in
  print_int (Bits.to_int !result);
  [%expect "1135"]

let%expect_test "Part 1 - Test D" =
  let _, result = test_file "../tests/d.input" false in
  print_int (Bits.to_int !result);
  [%expect "1"]

(* Part 2 Tests *)
let%expect_test "Part 2 - Test A" =
  let _, result = test_file "../tests/a.input" true in
  print_int (Bits.to_int !result);
  [%expect "6"]

let%expect_test "Part 2 - Test B" =
  let _, result = test_file "../tests/b.input" true in
  print_int (Bits.to_int !result);
  [%expect "6623"]

let%expect_test "Part 2 - Test C" =
  let _, result = test_file "../tests/c.input" true in
  print_int (Bits.to_int !result);
  [%expect "6558"]

(* Waveform for debugging *)
(* let%test_unit "basic_print" =
  print_endline "";
  let waves, result = test_file ("../tests/a.input") true in
  let () = Waveform.print ~display_height:30 ~display_width:120 waves in
  print_int (Bits.to_int !(result));
  () *)
