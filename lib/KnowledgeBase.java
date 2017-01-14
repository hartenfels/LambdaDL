import java.io.File;
import java.io.ByteArrayOutputStream;
import java.io.PrintWriter;
import org.semanticweb.HermiT.Reasoner;
import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.IRI;
import org.semanticweb.owlapi.model.OWLClassExpression;
import org.semanticweb.owlapi.model.OWLDataFactory;
import org.semanticweb.owlapi.model.OWLObjectPropertyExpression;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyManager;


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
}
