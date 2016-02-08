#TemPSS Dependency Grammar

The `TempssConstraints.g4` file in this directory is a simple ANTLR v4 grammar for parsing TemPSS constraint statements for Nektar++ solver parameter constraints.

These statements allow us to define dependencies across nodes in a TemPSS template tree for a Nektar++ solver.

##Constraint Grammar Structure

Constraint specifications begin with the `CONSTRAINT` keyword. This is followed by a `SOLVER` keyword defining the solver that the constraint relates to. The constraint itself then follows as a pair of `PROPERTY` expressions.

The structure is as follows:

```
CONSTRAINT solver_expression 
           property_expression 
           REQUIRES 
           property_expression

solver_expression :- SOLVER <solver_name>

property_expression :- PROPERTY <property_name>
                       OPTION <option_value>
```

`<solver_name>` can be one of `IncNavierStokes`, `CardiacElectrophysiology` or `CompressibleFlow`.

`<property_name>` is the name of the target property in the template written as a path from the first-level node with each node separated by `->`.

For example, consider the `CellModelType` parameter shown in the image below:

![Example profile tree]('ProfileProperties.png')

The property name for this parameter would be written `Physics -> CellModel -> CellModelType`.

An `<option_value>` can be either a single string value, e.g. `FitzhughNagumo` or a list of string values wrapped in square brackets, e.g. `['CourtemancheRamirezNattel98', 'FitzhughNagumo', 'TenTusscher']`