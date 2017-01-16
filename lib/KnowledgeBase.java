import java.io.File;
import java.io.ByteArrayOutputStream;
import java.io.PrintWriter;
import org.semanticweb.HermiT.Reasoner;
import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.IRI;
import org.semanticweb.owlapi.model.OWLClassExpression;
import org.semanticweb.owlapi.model.OWLDataFactory;
import org.semanticweb.owlapi.model.OWLNamedIndividual;
import org.semanticweb.owlapi.model.OWLObjectPropertyExpression;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyManager;
import org.semanticweb.owlapi.reasoner.NodeSet;


class KnowledgeBase {
    private OWLDataFactory df;
    private OWLOntology    onto;
    private Reasoner       hermit;

    public KnowledgeBase(String path) throws Exception {
        OWLOntologyManager mgr = OWLManager.createOWLOntologyManager();
        df     = mgr.getOWLDataFactory();
        onto   = mgr.loadOntologyFromOntologyDocument(new File(path));
        hermit = new Reasoner(onto);
    }


    private IRI toIRI(String s) {
        String expanded;
        try {
            expanded = hermit.getPrefixes().expandAbbreviatedIRI(s);
        }
        catch (IllegalArgumentException e) {
            expanded = s;
        }
        return IRI.create(expanded);
    }


    public OWLObjectPropertyExpression role(String s) {
        return df.getOWLObjectProperty(toIRI(s));
    }

    public OWLObjectPropertyExpression invert(OWLObjectPropertyExpression r) {
        return df.getOWLObjectInverseOf(r);
    }


    public OWLClassExpression concept(String s) {
        return df.getOWLClass(toIRI(s));
    }

    public OWLClassExpression everything() {
        return df.getOWLThing();
    }

    public OWLClassExpression nothing() {
        return df.getOWLNothing();
    }

    public OWLNamedIndividual nominal(String s) {
        return df.getOWLNamedIndividual(toIRI(s));
    }


    public OWLClassExpression not(OWLClassExpression c) {
        return df.getOWLObjectComplementOf(c);
    }

    public OWLClassExpression intersect(OWLClassExpression a,
                                        OWLClassExpression b) {
        return df.getOWLObjectIntersectionOf(a, b);
    }

    public OWLClassExpression union(OWLClassExpression a,
                                    OWLClassExpression b) {
        return df.getOWLObjectUnionOf(a, b);
    }

    public OWLClassExpression exists(OWLObjectPropertyExpression r,
                                     OWLClassExpression          c) {
        return df.getOWLObjectSomeValuesFrom(r, c);
    }

    public OWLClassExpression forAll(OWLObjectPropertyExpression r,
                                     OWLClassExpression          c) {
        return df.getOWLObjectAllValuesFrom(r, c);
    }


    public boolean satisfiable(OWLClassExpression c) {
        return hermit.isSatisfiable(c);
    }

    public boolean comparable(OWLClassExpression a, OWLClassExpression b) {
        return satisfiable(intersect(a, b));
    }


    private OWLNamedIndividual[] individuals(NodeSet<OWLNamedIndividual> set) {
        return set.getFlattened().toArray(new OWLNamedIndividual[0]);
    }

    public OWLNamedIndividual[] query(OWLClassExpression c) {
        return individuals(hermit.getInstances(c, false));
    }

    public OWLNamedIndividual[] project(OWLNamedIndividual          i,
                                        OWLObjectPropertyExpression r) {
        return individuals(hermit.getObjectPropertyValues(i, r));
    }


    public boolean member(OWLNamedIndividual i, OWLClassExpression c) {
        OWLClassExpression d = df.getOWLObjectComplementOf(c);
        return  hermit.isEntailed(df.getOWLClassAssertionAxiom(c, i))
            && !hermit.isEntailed(df.getOWLClassAssertionAxiom(d, i));
    }
}
