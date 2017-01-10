import java.io.File;
import java.io.ByteArrayOutputStream;
import java.io.PrintWriter;
import org.semanticweb.HermiT.Reasoner;
import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.OWLClassExpression;
import org.semanticweb.owlapi.model.OWLDataFactory;
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


    public String dumpHierarchies() {
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        PrintWriter           writer = new PrintWriter(stream);

        hermit.printHierarchies(writer, true, true, true);
        writer.close();

        return stream.toString();
    }


    public OWLClassExpression everything() {
        return df.getOWLThing();
    }

    public OWLClassExpression nothing() {
        return df.getOWLNothing();
    }
}
